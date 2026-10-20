package com.shopzo.app.features.products.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.entity.CategoryEntity
import com.shopzo.app.core.database.entity.ProductEntity
import com.shopzo.app.core.model.PriceTier
import com.shopzo.app.core.model.ProductUnit
import com.shopzo.app.core.model.StockStatus
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.core.ui.components.getStockStatus
import com.shopzo.app.core.utils.MoneyUtils
import com.shopzo.app.core.utils.ValidationUtils
import com.shopzo.app.features.products.data.ProductRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

data class PriceTierDraft(
    val id: String = UUID.randomUUID().toString(),
    var name: String = "",
    var quantity: String = "1",
    var unit: String = "KG",
    var price: String = "",
    var buyingPrice: String = ""
)

class ProductsViewModel(
    private val productRepository: ProductRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")
    private val _searchQuery = MutableStateFlow("")
    private val _stockFilter = MutableStateFlow<StockStatus?>(null)

    val categories: StateFlow<List<CategoryEntity>> = _shopId.flatMapLatest { shopId ->
        if (shopId.isNotEmpty()) productRepository.getCategoriesByShop(shopId) else flowOf(emptyList())
    }.onEach { list ->
        if (selectedCategoryId.isEmpty() && list.isNotEmpty()) {
            selectedCategoryId = list.first().id
        }
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
    var isTierProduct by mutableStateOf(false)
    val priceTiers = mutableStateListOf<PriceTierDraft>()
    var isLoading by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    fun addTier(name: String = "", quantity: String = "1", unit: String = "KG", price: String = "") {
        priceTiers.add(PriceTierDraft(name = name, quantity = quantity, unit = unit, price = price))
    }

    fun removeTier(index: Int) {
        if (index in priceTiers.indices) {
            priceTiers.removeAt(index)
        }
    }

    fun applyTierPresetsForUnit(unit: ProductUnit) {
        priceTiers.clear()
        when (unit) {
            ProductUnit.KG -> {
                priceTiers.add(PriceTierDraft(name = "100 Grams", quantity = "100", unit = "GRAM"))
                priceTiers.add(PriceTierDraft(name = "250 Grams", quantity = "250", unit = "GRAM"))
                priceTiers.add(PriceTierDraft(name = "500 Grams", quantity = "500", unit = "GRAM"))
                priceTiers.add(PriceTierDraft(name = "1 Kg", quantity = "1", unit = "KG"))
            }
            ProductUnit.LITRE -> {
                priceTiers.add(PriceTierDraft(name = "100 ml", quantity = "100", unit = "ML"))
                priceTiers.add(PriceTierDraft(name = "250 ml", quantity = "250", unit = "ML"))
                priceTiers.add(PriceTierDraft(name = "500 ml", quantity = "500", unit = "ML"))
                priceTiers.add(PriceTierDraft(name = "1 Litre", quantity = "1", unit = "LITRE"))
            }
            ProductUnit.PIECE -> {
                priceTiers.add(PriceTierDraft(name = "1 Piece", quantity = "1", unit = "PIECE"))
                priceTiers.add(PriceTierDraft(name = "Half Dozen", quantity = "6", unit = "PIECE"))
                priceTiers.add(PriceTierDraft(name = "1 Dozen", quantity = "12", unit = "PIECE"))
            }
            else -> {
                priceTiers.add(PriceTierDraft(name = "Standard Pack", quantity = "1", unit = unit.name))
            }
        }
    }

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

                priceTiers.clear()
                if (product.priceTiers.isNotBlank() && product.priceTiers != "[]") {
                    try {
                        val parsed = Json.decodeFromString<List<PriceTier>>(product.priceTiers)
                        parsed.forEach { t ->
                            priceTiers.add(
                                PriceTierDraft(
                                    id = t.id,
                                    name = t.name,
                                    quantity = if (t.quantity % 1.0 == 0.0) t.quantity.toInt().toString() else t.quantity.toString(),
                                    unit = t.unit,
                                    price = MoneyUtils.paiseToDecimalString(t.pricePaise),
                                    buyingPrice = if (t.buyingPricePaise > 0) MoneyUtils.paiseToDecimalString(t.buyingPricePaise) else ""
                                )
                            )
                        }
                        isTierProduct = priceTiers.isNotEmpty()
                    } catch (_: Exception) {
                        isTierProduct = false
                    }
                } else {
                    isTierProduct = false
                }
            }
        }
    }

    fun saveProduct(productId: String? = null, onSuccess: () -> Unit) {
        val nameError = ValidationUtils.validateProductName(productName)
        if (nameError != null) { errorMessage = nameError; return }
        if (selectedCategoryId.isEmpty()) { errorMessage = "Please select a category."; return }
        val buyError = ValidationUtils.validatePrice(buyingPrice, "Buying price", required = false)
        if (buyError != null) { errorMessage = buyError; return }
        val sellError = ValidationUtils.validatePrice(sellingPrice, "Selling price")
        if (sellError != null) { errorMessage = sellError; return }
        val qtyError = ValidationUtils.validateQuantity(quantity, required = false)
        if (qtyError != null) { errorMessage = qtyError; return }
        val minError = ValidationUtils.validateMinStockLevel(minStockLevel, required = false)
        if (minError != null) { errorMessage = minError; return }

        val buyPaise = if (buyingPrice.trim().isEmpty()) 0.0 else (MoneyUtils.rupeesToPaise(buyingPrice)?.toDouble() ?: run { errorMessage = "Enter a valid buying price."; return })
        val sellPaise = MoneyUtils.rupeesToPaise(sellingPrice) ?: run { errorMessage = "Enter a valid selling price."; return }

        val tiersJson = if (isTierProduct && priceTiers.isNotEmpty()) {
            val tierModels = priceTiers.filter { it.price.isNotBlank() }.map { draft ->
                val pPaise = MoneyUtils.rupeesToPaise(draft.price)?.toLong() ?: 0L
                val bPaise = if (draft.buyingPrice.isNotBlank()) MoneyUtils.rupeesToPaise(draft.buyingPrice)?.toLong() ?: 0L else 0L
                PriceTier(
                    id = draft.id,
                    name = draft.name.ifBlank { "${draft.quantity} ${draft.unit}" },
                    quantity = draft.quantity.toDoubleOrNull() ?: 1.0,
                    unit = draft.unit,
                    pricePaise = pPaise,
                    buyingPricePaise = bPaise
                )
            }
            Json.encodeToString(tierModels)
        } else "[]"

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
                    quantity = if (quantity.trim().isEmpty()) 0.0 else quantity.trim().toDouble(),
                    unit = selectedUnit.name,
                    minStockLevel = if (minStockLevel.trim().isEmpty()) 0.0 else minStockLevel.trim().toDouble(),
                    priceTiers = tiersJson,
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
                val cat = productRepository.addCategory(newCategoryName, _shopId.value)
                selectedCategoryId = cat.id
                newCategoryName = ""
                onSuccess()
            } catch (e: Exception) {
                e.printStackTrace()
                categoryError = e.localizedMessage ?: "Failed to add category"
            }
        }
    }

    fun addCategoryInline(categoryName: String, onSuccess: (String) -> Unit) {
        val error = ValidationUtils.validateCategoryName(categoryName)
        if (error != null) { categoryError = error; return }
        categoryError = null
        viewModelScope.launch {
            try {
                val cat = productRepository.addCategory(categoryName, _shopId.value)
                selectedCategoryId = cat.id
                onSuccess(cat.id)
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
        isTierProduct = false; priceTiers.clear()
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
