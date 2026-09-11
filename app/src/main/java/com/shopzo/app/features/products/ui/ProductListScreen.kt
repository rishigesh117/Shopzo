package com.shopzo.app.features.products.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.model.StockStatus
import com.shopzo.app.core.ui.components.EmptyState
import com.shopzo.app.core.ui.components.StockBadge
import com.shopzo.app.core.ui.components.getStockStatus
import com.shopzo.app.core.utils.MoneyUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductListScreen(
    viewModel: ProductsViewModel,
    onNavigateToAddProduct: () -> Unit,
    onNavigateToProductDetail: (String) -> Unit
) {
    val products by viewModel.filteredProducts.collectAsState()
    val categories by viewModel.categories.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Products") })
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onNavigateToAddProduct) {
                Icon(Icons.Filled.Add, contentDescription = "Add Product")
            }
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            // Search Bar
            OutlinedTextField(
                value = viewModel.searchQuery,
                onValueChange = { viewModel.updateSearchQuery(it) },
                placeholder = { Text("Search products...") },
                leadingIcon = { Icon(Icons.Filled.Search, null) },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                shape = MaterialTheme.shapes.medium
            )

            // Stock Filter Chips
            LazyRow(
                modifier = Modifier.padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    FilterChip(
                        selected = viewModel.stockFilter == null,
                        onClick = { viewModel.updateStockFilter(null) },
                        label = { Text("All") }
                    )
                }
                item {
                    FilterChip(
                        selected = viewModel.stockFilter == StockStatus.IN_STOCK,
                        onClick = { viewModel.updateStockFilter(StockStatus.IN_STOCK) },
                        label = { Text("In Stock") }
                    )
                }
                item {
                    FilterChip(
                        selected = viewModel.stockFilter == StockStatus.LOW_STOCK,
                        onClick = { viewModel.updateStockFilter(StockStatus.LOW_STOCK) },
                        label = { Text("Low Stock") }
                    )
                }
                item {
                    FilterChip(
                        selected = viewModel.stockFilter == StockStatus.OUT_OF_STOCK,
                        onClick = { viewModel.updateStockFilter(StockStatus.OUT_OF_STOCK) },
                        label = { Text("Out of Stock") }
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            if (products.isEmpty()) {
                EmptyState(
                    icon = Icons.Outlined.Inventory2,
                    title = "No Products Found",
                    subtitle = if (viewModel.searchQuery.isNotEmpty() || viewModel.stockFilter != null)
                        "Try changing your search or filter"
                    else "Tap + to add your first product"
                )
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(products, key = { it.id }) { product ->
                        val status = getStockStatus(product.quantity, product.minStockLevel)
                        val categoryName = viewModel.getCategoryName(product.categoryId)
                        val unitName = try {
                            com.shopzo.app.core.model.ProductUnit.valueOf(product.unit).displayName
                        } catch (_: Exception) { product.unit }

                        Card(
                            onClick = { onNavigateToProductDetail(product.id) },
                            modifier = Modifier.fillMaxWidth(),
                            shape = MaterialTheme.shapes.medium,
                            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = product.name,
                                            style = MaterialTheme.typography.titleMedium,
                                            fontWeight = FontWeight.SemiBold
                                        )
                                        Text(
                                            text = categoryName,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                    StockBadge(status = status)
                                }
                                Spacer(modifier = Modifier.height(8.dp))
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Column {
                                        Text("Buy: ${MoneyUtils.paiseToRupeeString(product.buyingPricePaise)}", style = MaterialTheme.typography.bodySmall)
                                        Text("Sell: ${MoneyUtils.paiseToRupeeString(product.sellingPricePaise)}", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Medium)
                                    }
                                    Text(
                                        text = "${product.quantity} $unitName",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
