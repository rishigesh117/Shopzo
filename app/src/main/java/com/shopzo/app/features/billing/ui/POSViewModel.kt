package com.shopzo.app.features.billing.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.entity.CategoryEntity
import com.shopzo.app.core.database.entity.CustomerEntity
import com.shopzo.app.core.database.entity.ProductEntity
import com.shopzo.app.core.database.entity.stockQuantity
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.features.billing.data.BillingRepository
import com.shopzo.app.features.billing.data.CartItem
import com.shopzo.app.features.customers.data.CustomerRepository
import com.shopzo.app.features.products.data.ProductRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class POSUiState(
    val searchQuery: String = "",
    val selectedCategoryId: String? = null,
    val cart: List<CartItem> = emptyList(),
    val selectedCustomer: CustomerEntity? = null,
    val paidAmountInput: String = "",
    val paymentMethod: String = "CASH", // CASH, UPI, CARD, CREDIT
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val checkoutSuccessBillId: String? = null
)

class POSViewModel(
    private val productRepository: ProductRepository,
    private val customerRepository: CustomerRepository,
    private val billingRepository: BillingRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")
    val shopId: StateFlow<String> = _shopId.asStateFlow()

    private val _uiState = MutableStateFlow(POSUiState())
    val uiState: StateFlow<POSUiState> = _uiState.asStateFlow()

    val categories: StateFlow<List<CategoryEntity>> = _shopId.flatMapLatest { id ->
        if (id.isNotEmpty()) productRepository.getCategoriesByShop(id) else flowOf(emptyList())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val products: StateFlow<List<ProductEntity>> = combine(_shopId, _uiState) { id, state ->
        Pair(id, state)
    }.flatMapLatest { (id, state) ->
        if (id.isEmpty()) flowOf(emptyList())
        else if (state.searchQuery.isNotBlank()) productRepository.searchProducts(id, state.searchQuery)
        else if (state.selectedCategoryId != null) productRepository.getProductsByCategory(id, state.selectedCategoryId)
        else productRepository.getProductsByShop(id)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val customers: StateFlow<List<CustomerEntity>> = _shopId.flatMapLatest { id ->
        if (id.isNotEmpty()) customerRepository.getCustomersByShop(id) else flowOf(emptyList())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        viewModelScope.launch {
            sessionManager.sessionFlow.collect { session ->
                _shopId.value = session?.shopId ?: ""
            }
        }
    }

    fun setSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
    }

    fun selectCategory(categoryId: String?) {
        _uiState.update { it.copy(selectedCategoryId = categoryId) }
    }

    fun selectCustomer(customer: CustomerEntity?) {
        _uiState.update { it.copy(selectedCustomer = customer) }
    }

    fun setPaymentMethod(method: String) {
        _uiState.update { it.copy(paymentMethod = method) }
    }

    fun setPaidAmountInput(input: String) {
        _uiState.update { it.copy(paidAmountInput = input) }
    }

    fun addToCart(product: ProductEntity, quantityToAdd: Double = 1.0) {
        val currentCart = _uiState.value.cart.toMutableList()
        val existingIndex = currentCart.indexOfFirst { it.productId == product.id }
        val currentQtyInCart = if (existingIndex >= 0) currentCart[existingIndex].quantity else 0.0
        val targetQty = currentQtyInCart + quantityToAdd

        if (targetQty > product.stockQuantity) {
            _uiState.update { it.copy(errorMessage = "Only ${product.stockQuantity} ${product.unit} available.") }
            return
        }

        if (existingIndex >= 0) {
            currentCart[existingIndex] = currentCart[existingIndex].copy(quantity = targetQty)
        } else {
            currentCart.add(
                CartItem(
                    productId = product.id,
                    productName = product.name,
                    quantity = targetQty,
                    unit = product.unit,
                    sellingPricePaise = product.sellingPricePaise,
                    buyingPricePaise = product.buyingPricePaise
                )
            )
        }

        _uiState.update { state ->
            val grandTotalPaise = currentCart.sumOf { (it.sellingPricePaise * it.quantity).toLong() }
            state.copy(
                cart = currentCart,
                paidAmountInput = (grandTotalPaise / 100.0).toString(),
                errorMessage = null
            )
        }
    }

    fun updateCartQuantity(productId: String, newQuantity: Double, availableStock: Double) {
        if (newQuantity <= 0.0) {
            removeFromCart(productId)
            return
        }
        if (newQuantity > availableStock) {
            _uiState.update { it.copy(errorMessage = "Only $availableStock available.") }
            return
        }

        val currentCart = _uiState.value.cart.toMutableList()
        val index = currentCart.indexOfFirst { it.productId == productId }
        if (index >= 0) {
            currentCart[index] = currentCart[index].copy(quantity = newQuantity)
            _uiState.update { state ->
                val grandTotalPaise = currentCart.sumOf { (it.sellingPricePaise * it.quantity).toLong() }
                state.copy(
                    cart = currentCart,
                    paidAmountInput = (grandTotalPaise / 100.0).toString(),
                    errorMessage = null
                )
            }
        }
    }

    fun removeFromCart(productId: String) {
        val currentCart = _uiState.value.cart.filterNot { it.productId == productId }
        _uiState.update { state ->
            val grandTotalPaise = currentCart.sumOf { (it.sellingPricePaise * it.quantity).toLong() }
            state.copy(
                cart = currentCart,
                paidAmountInput = (grandTotalPaise / 100.0).toString()
            )
        }
    }

    fun clearCart() {
        _uiState.update { it.copy(cart = emptyList(), paidAmountInput = "", errorMessage = null) }
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    fun clearCheckoutSuccess() {
        _uiState.update { it.copy(checkoutSuccessBillId = null) }
    }

    fun checkout() {
        val state = _uiState.value
        val shopIdVal = _shopId.value
        if (shopIdVal.isEmpty()) return
        if (state.cart.isEmpty()) {
            _uiState.update { it.copy(errorMessage = "Cart is empty.") }
            return
        }

        val grandTotalPaise = state.cart.sumOf { (it.sellingPricePaise * it.quantity).toLong() }
        val paidAmountDouble = state.paidAmountInput.toDoubleOrNull() ?: 0.0
        val paidAmountPaise = (paidAmountDouble * 100).toLong()

        if (paidAmountPaise > grandTotalPaise) {
            _uiState.update { it.copy(errorMessage = "Paid amount cannot exceed total bill amount.") }
            return
        }

        _uiState.update { it.copy(isLoading = true, errorMessage = null) }

        viewModelScope.launch {
            val result = billingRepository.createBill(
                shopId = shopIdVal,
                customerId = state.selectedCustomer?.id,
                customerNameSnapshot = state.selectedCustomer?.name ?: "Walk-in Customer",
                customerMobileSnapshot = state.selectedCustomer?.mobileNumber ?: "",
                cartItems = state.cart,
                paidAmountPaise = paidAmountPaise,
                paymentMethod = state.paymentMethod
            )

            result.fold(
                onSuccess = { bill ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            cart = emptyList(),
                            selectedCustomer = null,
                            paidAmountInput = "",
                            checkoutSuccessBillId = bill.id
                        )
                    }
                },
                onFailure = { err ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = err.message ?: "Failed to process bill."
                        )
                    }
                }
            )
        }
    }

    class Factory(
        private val productRepository: ProductRepository,
        private val customerRepository: CustomerRepository,
        private val billingRepository: BillingRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return POSViewModel(productRepository, customerRepository, billingRepository, sessionManager) as T
        }
    }
}
