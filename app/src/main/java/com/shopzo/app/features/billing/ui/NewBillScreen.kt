package com.shopzo.app.features.billing.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.database.entity.CategoryEntity
import com.shopzo.app.core.database.entity.CustomerEntity
import com.shopzo.app.core.database.entity.ProductEntity
import com.shopzo.app.core.database.entity.stockQuantity
import com.shopzo.app.core.ui.components.EmptyState
import com.shopzo.app.core.ui.components.StockBadge
import com.shopzo.app.core.ui.components.getStockStatus
import com.shopzo.app.core.utils.MoneyUtils
import com.shopzo.app.features.billing.data.CartItem
import com.shopzo.app.features.customers.ui.AddCustomerDialog
import com.shopzo.app.features.customers.ui.CustomerViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewBillScreen(
    viewModel: POSViewModel,
    customerViewModel: CustomerViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToBillDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val products by viewModel.products.collectAsState()
    val categories by viewModel.categories.collectAsState()
    val customers by viewModel.customers.collectAsState()

    var showCartBottomSheet by remember { mutableStateOf(false) }
    var editingCartItem by remember { mutableStateOf<CartItem?>(null) }
    var showAddCustomerDialog by remember { mutableStateOf(false) }

    val grandTotalPaise = remember(uiState.cart) {
        uiState.cart.sumOf { (it.sellingPricePaise * it.quantity).toLong() }
    }

    LaunchedEffect(uiState.checkoutSuccessBillId) {
        uiState.checkoutSuccessBillId?.let { billId ->
            viewModel.clearCheckoutSuccess()
            onNavigateToBillDetail(billId)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("New Bill / POS", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (uiState.cart.isNotEmpty()) {
                        IconButton(onClick = { viewModel.clearCart() }) {
                            Icon(Icons.Filled.Delete, contentDescription = "Clear Cart", tint = MaterialTheme.colorScheme.error)
                        }
                    }
                }
            )
        },
        bottomBar = {
            if (uiState.cart.isNotEmpty()) {
                Surface(
                    tonalElevation = 8.dp,
                    shadowElevation = 8.dp,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "${uiState.cart.sumOf { it.quantity }} item(s)",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = MoneyUtils.formatPaise(grandTotalPaise),
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        Button(
                            onClick = { showCartBottomSheet = true },
                            shape = RoundedCornerShape(12.dp),
                            contentPadding = PaddingValues(horizontal = 24.dp, vertical = 12.dp)
                        ) {
                            Icon(Icons.Filled.ShoppingCart, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("View Cart / Checkout", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Error Message Snackbar
            uiState.errorMessage?.let { msg ->
                Surface(
                    color = MaterialTheme.colorScheme.errorContainer,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(msg, color = MaterialTheme.colorScheme.onErrorContainer, style = MaterialTheme.typography.bodyMedium)
                        IconButton(onClick = { viewModel.clearError() }) {
                            Icon(Icons.Filled.Close, contentDescription = "Dismiss", tint = MaterialTheme.colorScheme.onErrorContainer)
                        }
                    }
                }
            }

            // Search Bar
            OutlinedTextField(
                value = uiState.searchQuery,
                onValueChange = { viewModel.setSearchQuery(it) },
                placeholder = { Text("Search product by name, brand, category...") },
                leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                trailingIcon = {
                    if (uiState.searchQuery.isNotEmpty()) {
                        IconButton(onClick = { viewModel.setSearchQuery("") }) {
                            Icon(Icons.Filled.Close, contentDescription = "Clear search")
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            )

            // Category Filter Chips
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(bottom = 8.dp)
            ) {
                item {
                    FilterChip(
                        selected = uiState.selectedCategoryId == null,
                        onClick = { viewModel.selectCategory(null) },
                        label = { Text("All") }
                    )
                }
                items(categories) { cat ->
                    FilterChip(
                        selected = uiState.selectedCategoryId == cat.id,
                        onClick = { viewModel.selectCategory(cat.id) },
                        label = { Text(cat.name) }
                    )
                }
            }

            // Products Grid
            if (products.isEmpty()) {
                EmptyState(
                    icon = Icons.Filled.Search,
                    title = "No products found",
                    subtitle = if (uiState.searchQuery.isNotEmpty()) "Try a different search query" else "No available products in stock"
                )
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    items(products, key = { it.id }) { product ->
                        val cartItem = uiState.cart.find { it.productId == product.id }
                        val qtyInCart = cartItem?.quantity ?: 0.0

                        ProductPOSCard(
                            product = product,
                            quantityInCart = qtyInCart,
                            onAddToCart = { viewModel.addToCart(product, 1.0) }
                        )
                    }
                }
            }
        }
    }

    // Direct Quantity Edit Dialog
    editingCartItem?.let { item ->
        val product = products.find { it.id == item.productId }
        var qtyInput by remember { mutableStateOf(item.quantity.toString()) }

        AlertDialog(
            onDismissRequest = { editingCartItem = null },
            title = { Text("Edit Quantity: ${item.productName}") },
            text = {
                Column {
                    Text("Stock Available: ${product?.stockQuantity ?: 0.0} ${item.unit}", style = MaterialTheme.typography.bodySmall)
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = qtyInput,
                        onValueChange = { qtyInput = it },
                        label = { Text("Quantity (${item.unit})") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        val newQty = qtyInput.toDoubleOrNull() ?: 0.0
                        viewModel.updateCartQuantity(item.productId, newQty, product?.stockQuantity ?: 0.0)
                        editingCartItem = null
                    }
                ) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { editingCartItem = null }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Add Customer Quick Dialog
    if (showAddCustomerDialog) {
        AddCustomerDialog(
            viewModel = customerViewModel,
            onDismiss = { showAddCustomerDialog = false },
            onCustomerCreated = { customer ->
                viewModel.selectCustomer(customer)
                showAddCustomerDialog = false
            }
        )
    }

    // Cart & Checkout Bottom Sheet
    if (showCartBottomSheet) {
        ModalBottomSheet(
            onDismissRequest = { showCartBottomSheet = false },
            shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 8.dp)
                    .fillMaxHeight(0.85f)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Cart Summary", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    IconButton(onClick = { showCartBottomSheet = false }) {
                        Icon(Icons.Filled.Close, contentDescription = "Close")
                    }
                }

                Divider(modifier = Modifier.padding(vertical = 8.dp))

                // Cart Items List
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(uiState.cart) { cartItem ->
                        val product = products.find { it.id == cartItem.productId }
                        CartItemRow(
                            cartItem = cartItem,
                            availableStock = product?.stockQuantity ?: cartItem.quantity,
                            onQuantityChange = { newQty ->
                                viewModel.updateCartQuantity(cartItem.productId, newQty, product?.stockQuantity ?: cartItem.quantity)
                            },
                            onDirectEdit = { editingCartItem = cartItem },
                            onRemove = { viewModel.removeFromCart(cartItem.productId) }
                        )
                    }
                }

                Divider(modifier = Modifier.padding(vertical = 8.dp))

                // Customer Selection Section
                Text("Customer", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    var customerExpanded by remember { mutableStateOf(false) }
                    ExposedDropdownMenuBox(
                        expanded = customerExpanded,
                        onExpandedChange = { customerExpanded = !customerExpanded },
                        modifier = Modifier.weight(1f)
                    ) {
                        OutlinedTextField(
                            value = uiState.selectedCustomer?.let { "${it.name} (${it.mobileNumber})" } ?: "Walk-in Customer",
                            onValueChange = {},
                            readOnly = true,
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = customerExpanded) },
                            modifier = Modifier
                                .menuAnchor()
                                .fillMaxWidth()
                        )
                        ExposedDropdownMenu(
                            expanded = customerExpanded,
                            onDismissRequest = { customerExpanded = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("Walk-in Customer") },
                                onClick = {
                                    viewModel.selectCustomer(null)
                                    customerExpanded = false
                                }
                            )
                            customers.forEach { cust ->
                                DropdownMenuItem(
                                    text = { Text("${cust.name} (${cust.mobileNumber})") },
                                    onClick = {
                                        viewModel.selectCustomer(cust)
                                        customerExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    IconButton(
                        onClick = { showAddCustomerDialog = true },
                        modifier = Modifier
                            .clip(RoundedCornerShape(12.dp))
                            .background(MaterialTheme.colorScheme.primaryContainer)
                    ) {
                        Icon(Icons.Filled.PersonAdd, contentDescription = "Add Customer", tint = MaterialTheme.colorScheme.onPrimaryContainer)
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Payment Details
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Grand Total:", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(MoneyUtils.formatPaise(grandTotalPaise), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Payment Method Chips
                Text("Payment Method", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("CASH", "UPI", "CARD", "CREDIT").forEach { method ->
                        FilterChip(
                            selected = uiState.paymentMethod == method,
                            onClick = { viewModel.setPaymentMethod(method) },
                            label = { Text(method) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Paid Amount & Remaining Auto-calculation
                val paidDouble = uiState.paidAmountInput.toDoubleOrNull() ?: 0.0
                val paidPaise = (paidDouble * 100).toLong()
                val remainingPaise = (grandTotalPaise - paidPaise).coerceAtLeast(0L)

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = uiState.paidAmountInput,
                        onValueChange = { viewModel.setPaidAmountInput(it) },
                        label = { Text("Paid Amount (₹)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true,
                        modifier = Modifier.weight(1f)
                    )

                    Column(horizontalAlignment = Alignment.End) {
                        Text("Remaining Due:", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text(
                            text = MoneyUtils.formatPaise(remainingPaise),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = if (remainingPaise > 0) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Complete Bill Button
                Button(
                    onClick = {
                        viewModel.checkout()
                        showCartBottomSheet = false
                    },
                    enabled = !uiState.isLoading && uiState.cart.isNotEmpty(),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                ) {
                    if (uiState.isLoading) {
                        CircularProgressIndicator(modifier = Modifier.size(24.dp), color = MaterialTheme.colorScheme.onPrimary)
                    } else {
                        Text("Complete Bill & Checkout", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
            }
        }
    }
}

@Composable
fun ProductPOSCard(
    product: ProductEntity,
    quantityInCart: Double,
    onAddToCart: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                StockBadge(status = getStockStatus(product.quantity, product.minStockLevel))
                if (quantityInCart > 0) {
                    Surface(
                        color = MaterialTheme.colorScheme.primaryContainer,
                        shape = CircleShape
                    ) {
                        Text(
                            text = "${quantityInCart.let { if (it % 1.0 == 0.0) it.toInt().toString() else it.toString() }} in cart",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = product.name,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                maxLines = 1
            )
            if (!product.brand.isNullOrEmpty()) {
                Text(
                    text = product.brand,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = MoneyUtils.formatPaise(product.sellingPricePaise),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )

                IconButton(
                    onClick = onAddToCart,
                    enabled = product.stockQuantity > 0,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(if (product.stockQuantity > 0) MaterialTheme.colorScheme.primary else Color.Gray)
                        .size(36.dp)
                ) {
                    Icon(Icons.Filled.Add, contentDescription = "Add to Cart", tint = Color.White)
                }
            }
        }
    }
}

@Composable
fun CartItemRow(
    cartItem: CartItem,
    availableStock: Double,
    onQuantityChange: (Double) -> Unit,
    onDirectEdit: () -> Unit,
    onRemove: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(cartItem.productName, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                Text(
                    "${MoneyUtils.formatPaise(cartItem.sellingPricePaise)} / ${cartItem.unit}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    "Subtotal: ${MoneyUtils.formatPaise(cartItem.subtotalPaise)}",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )
            }

            // Quantity Controls [-] 2 [+] and edit
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(
                    onClick = { onQuantityChange(cartItem.quantity - 1.0) },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(Icons.Filled.Remove, contentDescription = "Decrease")
                }

                Text(
                    text = if (cartItem.quantity % 1.0 == 0.0) cartItem.quantity.toInt().toString() else cartItem.quantity.toString(),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .clickable(onClick = onDirectEdit)
                        .padding(horizontal = 8.dp)
                )

                IconButton(
                    onClick = { onQuantityChange(cartItem.quantity + 1.0) },
                    enabled = cartItem.quantity + 1.0 <= availableStock,
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(Icons.Filled.Add, contentDescription = "Increase")
                }

                IconButton(onClick = onRemove, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Filled.Delete, contentDescription = "Remove", tint = MaterialTheme.colorScheme.error)
                }
            }
        }
    }
}
