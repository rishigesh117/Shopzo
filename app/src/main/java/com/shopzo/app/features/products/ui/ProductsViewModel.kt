package com.shopzo.app.features.products.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.entity.CategoryEntity
import com.shopzo.app.core.database.entity.ProductEntity
import com.shopzo.app.core.model.ProductUnit
import com.shopzo.app.core.model.StockStatus
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.core.ui.components.getStockStatus
import com.shopzo.app.core.utils.MoneyUtils
import com.shopzo.app.core.utils.ValidationUtils
import com.shopzo.app.features.products.data.ProductRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.UUID

class ProductsViewModel(
    private val productRepository: ProductRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")
    private val _searchQuery = MutableStateFlow("")
    private val _stockFilter = MutableStateFlow<StockStatus?>(null)

    val categories: StateFlow<List<CategoryEntity>> = _shopId.flatMapLatest { shopId ->
        if (shopId.isNotEmpty()) productRepository.getCategoriesByShop(shopId) else flowOf(emptyList())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val allProducts: StateFlow<List<ProductEntity>> = _shopId.flatMapLatest { shopId ->
        if (shopId.isNotEmpty()) productRepository.getProductsByShop(shopId) else flowOf(emptyList())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val filteredProducts: StateFlow<List<ProductEntity>> = combine(
        allProducts, _searchQuery, _stockFilter
    ) { products, query, filter ->
        var result = products
        if (query.isNotBlank()) {
            val q = query.lowercase()
            result = result.filter {
                it.name.lowercase().contains(q) ||
                (it.brand?.lowercase()?.contains(q) == true)
            }
        }
        if (filter != null) {
            result = result.filter { getStockStatus(it.quantity, it.minStockLevel) == filter }
        }
        result
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    var searchQuery by mutableStateOf("")
        private set
    var stockFilter by mutableStateOf<StockStatus?>(null)
        private set

    // Product form state
    var productName by mutableStateOf("")
    var selectedCategoryId by mutableStateOf("")
    var brand by mutableStateOf("")
    var buyingPrice by mutableStateOf("")
    var sellingPrice by mutableStateOf("")
    var quantity by mutableStateOf("")
    var selectedUnit by mutableStateOf(ProductUnit.PIECE)
    var minStockLevel by mutableStateOf("")
    var isLoading by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    // Category management
    var newCategoryName by mutableStateOf("")
    var categoryError by mutableStateOf<String?>(null)
        private set

    init {
        viewModelScope.launch {
            sessionManager.sessionFlow.collect { session ->
                _shopId.value = session?.shopId ?: ""
            }
        }
    }

    fun updateSearchQuery(query: String) {
        searchQuery = query
        _searchQuery.value = query
    }

    fun updateStockFilter(filter: StockStatus?) {
        stockFilter = filter
        _stockFilter.value = filter
    }

    fun loadProductForEdit(productId: String) {
        viewModelScope.launch {
            val product = productRepository.getProductById(productId)
            if (product != null) {
                productName = product.name
                selectedCategoryId = product.categoryId
                brand = product.brand ?: ""
                buyingPrice = MoneyUtils.paiseToDecimalString(product.buyingPricePaise)
                sellingPrice = MoneyUtils.paiseToDecimalString(product.sellingPricePaise)
                quantity = product.quantity.toString()
                selectedUnit = try { ProductUnit.valueOf(product.unit) } catch (_: Exception) { ProductUnit.PIECE }
                minStockLevel = product.minStockLevel.toString()
            }
        }
    }

    fun saveProduct(productId: String? = null, onSuccess: () -> Unit) {
        val nameError = ValidationUtils.validateProductName(productName)
        if (nameError != null) { errorMessage = nameError; return }
        if (selectedCategoryId.isEmpty()) { errorMessage = "Please select a category."; return }
        val buyError = ValidationUtils.validatePrice(buyingPrice, "Buying price")
        if (buyError != null) { errorMessage = buyError; return }
        val sellError = ValidationUtils.validatePrice(sellingPrice, "Selling price")
        if (sellError != null) { errorMessage = sellError; return }
        val qtyError = ValidationUtils.validateQuantity(quantity)
        if (qtyError != null) { errorMessage = qtyError; return }
        val minError = ValidationUtils.validateMinStockLevel(minStockLevel)
        if (minError != null) { errorMessage = minError; return }

        val buyPaise = MoneyUtils.rupeesToPaise(buyingPrice)
        val sellPaise = MoneyUtils.rupeesToPaise(sellingPrice)
        if (buyPaise == null || sellPaise == null) { errorMessage = "Enter valid prices."; return }

        isLoading = true
        errorMessage = null
        viewModelScope.launch {
            try {
                val now = System.currentTimeMillis()
                val product = ProductEntity(
                    id = productId ?: UUID.randomUUID().toString(),
                    name = productName.trim(),
                    categoryId = selectedCategoryId,
                    brand = brand.trim().ifEmpty { null },
                    buyingPricePaise = buyPaise.toLong(),
                    sellingPricePaise = sellPaise.toLong(),
                    quantity = quantity.trim().toDouble(),
                    unit = selectedUnit.name,
                    minStockLevel = minStockLevel.trim().toDouble(),
                    shopId = _shopId.value,
                    createdAt = if (productId != null) {
                        productRepository.getProductById(productId)?.createdAt ?: now
                    } else now,
                    updatedAt = now
                )
                if (productId != null) {
                    productRepository.updateProduct(product)
                } else {
                    productRepository.addProduct(product)
                }
                isLoading = false
                resetForm()
                onSuccess()
            } catch (e: Exception) {
                e.printStackTrace()
                errorMessage = e.localizedMessage?.takeIf { it.isNotBlank() } ?: "Failed to save product."
                isLoading = false
            }
        }
    }

    fun deleteProduct(productId: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            try {
                productRepository.deleteProduct(productId)
                onSuccess()
            } catch (e: Exception) {
                e.printStackTrace()
                errorMessage = e.localizedMessage ?: "Failed to delete product"
            }
        }
    }

    // Categories
    fun addCategory(onSuccess: () -> Unit) {
        val error = ValidationUtils.validateCategoryName(newCategoryName)
        if (error != null) { categoryError = error; return }
        categoryError = null
        viewModelScope.launch {
            try {
                productRepository.addCategory(newCategoryName, _shopId.value)
                newCategoryName = ""
                onSuccess()
            } catch (e: Exception) {
                e.printStackTrace()
                categoryError = e.localizedMessage ?: "Failed to add category"
            }
        }
    }

    fun renameCategory(category: CategoryEntity, newName: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            try {
                productRepository.updateCategory(category.copy(name = newName.trim()))
                onSuccess()
            } catch (e: Exception) {
                e.printStackTrace()
                categoryError = e.localizedMessage ?: "Failed to rename category"
            }
        }
    }

    fun deleteCategory(categoryId: String, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                val result = productRepository.deleteCategory(categoryId)
                onResult(result)
            } catch (e: Exception) {
                e.printStackTrace()
                onResult(false)
            }
        }
    }

    fun getCategoryName(categoryId: String): String {
        return categories.value.find { it.id == categoryId }?.name ?: "Unknown"
    }

    private fun resetForm() {
        productName = ""; selectedCategoryId = ""; brand = ""
        buyingPrice = ""; sellingPrice = ""; quantity = ""
        selectedUnit = ProductUnit.PIECE; minStockLevel = ""
    }

    fun clearError() { errorMessage = null }

    class Factory(
        private val productRepository: ProductRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return ProductsViewModel(productRepository, sessionManager) as T
        }
    }
}
