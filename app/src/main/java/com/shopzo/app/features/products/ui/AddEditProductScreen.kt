package com.shopzo.app.features.products.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.model.ProductUnit

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditProductScreen(
    viewModel: ProductsViewModel,
    productId: String? = null,
    onNavigateBack: () -> Unit
) {
    val categories by viewModel.categories.collectAsState()
    val focusManager = LocalFocusManager.current
    val isEdit = productId != null
    var unitExpanded by remember { mutableStateOf(false) }
    var categoryExpanded by remember { mutableStateOf(false) }

    LaunchedEffect(productId) {
        if (productId != null) viewModel.loadProductForEdit(productId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (isEdit) "Edit Product" else "Add Product") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(24.dp)
        ) {
            // Product Name
            OutlinedTextField(
                value = viewModel.productName,
                onValueChange = { viewModel.productName = it; viewModel.clearError() },
                label = { Text("Product Name *") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
                keyboardActions = KeyboardActions(onNext = { focusManager.moveFocus(FocusDirection.Down) }),
                modifier = Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.medium
            )
            Spacer(modifier = Modifier.height(12.dp))

            // Category Dropdown
            ExposedDropdownMenuBox(expanded = categoryExpanded, onExpandedChange = { categoryExpanded = it }) {
                OutlinedTextField(
                    value = categories.find { it.id == viewModel.selectedCategoryId }?.name ?: "",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Category *") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                    modifier = Modifier.fillMaxWidth().menuAnchor(),
                    shape = MaterialTheme.shapes.medium
                )
                ExposedDropdownMenu(expanded = categoryExpanded, onDismissRequest = { categoryExpanded = false }) {
                    categories.forEach { cat ->
                        DropdownMenuItem(
                            text = { Text(cat.name) },
                            onClick = {
                                viewModel.selectedCategoryId = cat.id
                                categoryExpanded = false
                            }
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(12.dp))

            // Brand
            OutlinedTextField(
                value = viewModel.brand,
                onValueChange = { viewModel.brand = it },
                label = { Text("Brand (Optional)") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
                keyboardActions = KeyboardActions(onNext = { focusManager.moveFocus(FocusDirection.Down) }),
                modifier = Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.medium
            )
            Spacer(modifier = Modifier.height(12.dp))

            // Prices Row
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = viewModel.buyingPrice,
                    onValueChange = { viewModel.buyingPrice = it; viewModel.clearError() },
                    label = { Text("Buying Price (₹) *") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal, imeAction = ImeAction.Next),
                    keyboardActions = KeyboardActions(onNext = { focusManager.moveFocus(FocusDirection.Down) }),
                    modifier = Modifier.weight(1f),
                    shape = MaterialTheme.shapes.medium
                )
                OutlinedTextField(
                    value = viewModel.sellingPrice,
                    onValueChange = { viewModel.sellingPrice = it; viewModel.clearError() },
                    label = { Text("Selling Price (₹) *") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal, imeAction = ImeAction.Next),
                    keyboardActions = KeyboardActions(onNext = { focusManager.moveFocus(FocusDirection.Down) }),
                    modifier = Modifier.weight(1f),
                    shape = MaterialTheme.shapes.medium
                )
            }
            Spacer(modifier = Modifier.height(12.dp))

            // Quantity and Unit Row
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = viewModel.quantity,
                    onValueChange = { viewModel.quantity = it; viewModel.clearError() },
                    label = { Text("Quantity *") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal, imeAction = ImeAction.Next),
                    keyboardActions = KeyboardActions(onNext = { focusManager.moveFocus(FocusDirection.Down) }),
                    modifier = Modifier.weight(1f),
                    shape = MaterialTheme.shapes.medium
                )

                ExposedDropdownMenuBox(
                    expanded = unitExpanded,
                    onExpandedChange = { unitExpanded = it },
                    modifier = Modifier.weight(1f)
                ) {
                    OutlinedTextField(
                        value = viewModel.selectedUnit.displayName,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Unit") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = unitExpanded) },
                        modifier = Modifier.fillMaxWidth().menuAnchor(),
                        shape = MaterialTheme.shapes.medium
                    )
                    ExposedDropdownMenu(expanded = unitExpanded, onDismissRequest = { unitExpanded = false }) {
                        ProductUnit.entries.forEach { unit ->
                            DropdownMenuItem(
                                text = { Text(unit.displayName) },
                                onClick = { viewModel.selectedUnit = unit; unitExpanded = false }
                            )
                        }
                    }
                }
            }
            Spacer(modifier = Modifier.height(12.dp))

            // Minimum Stock Level
            OutlinedTextField(
                value = viewModel.minStockLevel,
                onValueChange = { viewModel.minStockLevel = it; viewModel.clearError() },
                label = { Text("Minimum Stock Level *") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal, imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { focusManager.clearFocus() }),
                modifier = Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.medium,
                supportingText = { Text("Alert when quantity drops below this level") }
            )

            AnimatedVisibility(visible = viewModel.errorMessage != null) {
                Text(
                    text = viewModel.errorMessage ?: "",
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.fillMaxWidth().padding(top = 8.dp)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = { viewModel.saveProduct(productId = productId, onSuccess = onNavigateBack) },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = MaterialTheme.shapes.medium,
                enabled = !viewModel.isLoading
            ) {
                if (viewModel.isLoading) {
                    CircularProgressIndicator(Modifier.size(24.dp), MaterialTheme.colorScheme.onPrimary, strokeWidth = 2.dp)
                } else {
                    Text(if (isEdit) "Update Product" else "Add Product", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }
}
