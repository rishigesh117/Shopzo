package com.shopzo.app.features.stock.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.outlined.History
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.model.AdjustmentReason
import com.shopzo.app.core.model.StockMovementType
import com.shopzo.app.core.ui.components.EmptyState
import com.shopzo.app.core.ui.theme.StockGreen
import com.shopzo.app.core.ui.theme.StockRed
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StockHistoryScreen(
    productId: String,
    viewModel: StockViewModel,
    onNavigateBack: () -> Unit
) {
    val movements by viewModel.getMovementsForProduct(productId).collectAsState(initial = emptyList())
    val dateFormat = remember { SimpleDateFormat("dd MMM yyyy — hh:mm a", Locale.getDefault()) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Stock History") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        if (movements.isEmpty()) {
            EmptyState(
                icon = Icons.Outlined.History,
                title = "No Stock History",
                subtitle = "Stock changes will appear here",
                modifier = Modifier.padding(padding)
            )
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(movements, key = { it.id }) { movement ->
                    val isRestock = movement.type == StockMovementType.RESTOCK.name
                    val reasonName = movement.reason?.let { r ->
                        try { AdjustmentReason.valueOf(r).displayName } catch (_: Exception) { r }
                    }

                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.medium,
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = if (isRestock) "RESTOCK" else reasonName ?: "ADJUSTMENT",
                                    style = MaterialTheme.typography.labelLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isRestock) StockGreen else StockRed
                                )
                                Text(
                                    text = "${if (movement.quantityChange >= 0) "+" else ""}${movement.quantityChange}",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = if (movement.quantityChange >= 0) StockGreen else StockRed
                                )
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "${movement.previousQuantity} → ${movement.newQuantity}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            if (movement.supplier != null) {
                                Text(
                                    text = "Supplier: ${movement.supplier}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            if (movement.notes != null) {
                                Text(
                                    text = "Note: ${movement.notes}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = dateFormat.format(Date(movement.createdAt)),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                            )
                        }
                    }
                }
            }
        }
    }
}
