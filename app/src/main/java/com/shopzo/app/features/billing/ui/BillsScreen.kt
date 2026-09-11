package com.shopzo.app.features.billing.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.database.entity.BillEntity
import com.shopzo.app.core.ui.components.EmptyState
import com.shopzo.app.core.ui.theme.StockOrange
import com.shopzo.app.core.ui.theme.StockRed
import com.shopzo.app.core.ui.theme.Teal700
import com.shopzo.app.core.utils.MoneyUtils
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BillsScreen(
    viewModel: BillsViewModel,
    onNavigateToNewBill: () -> Unit,
    onNavigateToBillDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val bills by viewModel.bills.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Bills & Sales History", fontWeight = FontWeight.Bold) }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = onNavigateToNewBill,
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            ) {
                Row(modifier = Modifier.padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("New Bill", fontWeight = FontWeight.Bold)
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Search field
            OutlinedTextField(
                value = uiState.searchQuery,
                onValueChange = { viewModel.setSearchQuery(it) },
                placeholder = { Text("Search by bill # or customer name/mobile...") },
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

            // Filter Tabs
            TabRow(
                selectedTabIndex = when (uiState.selectedFilter) {
                    "ALL" -> 0
                    "PAID" -> 1
                    "PARTIALLY_PAID" -> 2
                    "PENDING" -> 3
                    else -> 0
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Tab(
                    selected = uiState.selectedFilter == "ALL",
                    onClick = { viewModel.setFilter("ALL") },
                    text = { Text("All") }
                )
                Tab(
                    selected = uiState.selectedFilter == "PAID",
                    onClick = { viewModel.setFilter("PAID") },
                    text = { Text("Paid") }
                )
                Tab(
                    selected = uiState.selectedFilter == "PARTIALLY_PAID",
                    onClick = { viewModel.setFilter("PARTIALLY_PAID") },
                    text = { Text("Partial") }
                )
                Tab(
                    selected = uiState.selectedFilter == "PENDING",
                    onClick = { viewModel.setFilter("PENDING") },
                    text = { Text("Pending") }
                )
            }

            if (bills.isEmpty()) {
                EmptyState(
                    icon = Icons.Filled.Receipt,
                    title = "No bills found",
                    subtitle = if (uiState.searchQuery.isNotEmpty()) "No bills matching search query" else "Tap 'New Bill' to create your first POS transaction."
                )
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(bills, key = { it.id }) { bill ->
                        BillCard(
                            bill = bill,
                            onClick = { onNavigateToBillDetail(bill.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun BillCard(
    bill: BillEntity,
    onClick: () -> Unit
) {
    val dateFormat = remember { SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault()) }

    val (statusText, statusBg, statusFg) = when (bill.paymentStatus) {
        "PAID" -> Triple("PAID", Teal700.copy(alpha = 0.15f), Teal700)
        "PARTIALLY_PAID" -> Triple("PARTIAL", StockOrange.copy(alpha = 0.15f), StockOrange)
        else -> Triple("PENDING", StockRed.copy(alpha = 0.15f), StockRed)
    }

    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = bill.billNumber,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )

                Surface(
                    color = statusBg,
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(
                        text = statusText,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = statusFg,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = bill.customerNameSnapshot + if (bill.customerMobileSnapshot.isNotEmpty()) " (${bill.customerMobileSnapshot})" else "",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text("Total: ${MoneyUtils.formatPaise(bill.grandTotalPaise)}", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                    if (bill.pendingAmountPaise > 0) {
                        Text("Due: ${MoneyUtils.formatPaise(bill.pendingAmountPaise)}", style = MaterialTheme.typography.bodySmall, color = StockRed, fontWeight = FontWeight.SemiBold)
                    }
                }

                Text(
                    text = dateFormat.format(Date(bill.createdAt)),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
