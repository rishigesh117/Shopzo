package com.shopzo.app.features.reports.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.model.Permission
import com.shopzo.app.core.ui.components.EmptyState
import com.shopzo.app.core.ui.components.PermissionGate
import com.shopzo.app.core.ui.theme.StockOrange
import com.shopzo.app.core.ui.theme.StockRed
import com.shopzo.app.core.ui.theme.Teal700
import com.shopzo.app.core.utils.MoneyUtils
import com.shopzo.app.features.reports.data.BestSellerMetric
import com.shopzo.app.features.reports.data.DateRangePeriod

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReportsScreen(
    viewModel: ReportsViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToCustomerDetail: (String) -> Unit
) {
    PermissionGate(
        permission = Permission.REPORTS_VIEW,
        fallback = {
            Scaffold(
                topBar = {
                    TopAppBar(
                        title = { Text("Reports", fontWeight = FontWeight.Bold) },
                        navigationIcon = {
                            IconButton(onClick = onNavigateBack) {
                                Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                            }
                        }
                    )
                }
            ) { padding ->
                Box(modifier = Modifier.fillMaxSize().padding(padding)) {
                    EmptyState(
                        icon = Icons.Filled.Lock,
                        title = "Access Restricted",
                        subtitle = "You do not have permission to view business reports."
                    )
                }
            }
        }
    ) {
        val uiState by viewModel.uiState.collectAsState()
        val salesReport by viewModel.salesReport.collectAsState()
        val profitReport by viewModel.profitReport.collectAsState()
        val stockReport by viewModel.stockReport.collectAsState()
        val bestSellers by viewModel.bestSellers.collectAsState()
        val customersWithDues by viewModel.customersWithDues.collectAsState()

        var selectedTab by remember { mutableStateOf(0) } // 0=Sales, 1=Profit, 2=Stock, 3=Dues, 4=Best Sellers

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Business Reports", fontWeight = FontWeight.Bold) },
                    navigationIcon = {
                        IconButton(onClick = onNavigateBack) {
                            Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                        }
                    }
                )
            }
        ) { padding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                // Date Period Chips Row
                LazyRow(
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(DateRangePeriod.values().filter { it != DateRangePeriod.CUSTOM }) { period ->
                        FilterChip(
                            selected = uiState.selectedPeriod == period,
                            onClick = { viewModel.setPeriod(period) },
                            label = { Text(period.displayName) }
                        )
                    }
                }

                // Section Tabs
                ScrollableTabRow(selectedTabIndex = selectedTab, edgePadding = 16.dp, modifier = Modifier.fillMaxWidth()) {
                    Tab(selected = selectedTab == 0, onClick = { selectedTab = 0 }, text = { Text("Sales") })
                    Tab(selected = selectedTab == 1, onClick = { selectedTab = 1 }, text = { Text("Profit") })
                    Tab(selected = selectedTab == 2, onClick = { selectedTab = 2 }, text = { Text("Stock") })
                    Tab(selected = selectedTab == 3, onClick = { selectedTab = 3 }, text = { Text("Dues") })
                    Tab(selected = selectedTab == 4, onClick = { selectedTab = 4 }, text = { Text("Best Sellers") })
                }

                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    when (selectedTab) {
                        0 -> {
                            // Sales Report
                            item {
                                ReportStatCard("Total Sales", MoneyUtils.formatPaise(salesReport.totalSalesPaise), Teal700)
                            }
                            item {
                                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                                    ReportStatCard("Total Bills", "${salesReport.billCount}", MaterialTheme.colorScheme.primary, Modifier.weight(1f))
                                    ReportStatCard("Products Sold", "${salesReport.totalProductsSold}", StockOrange, Modifier.weight(1f))
                                }
                            }
                            item {
                                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                                    ReportStatCard("Avg Bill Value", MoneyUtils.formatPaise(salesReport.averageBillValuePaise), MaterialTheme.colorScheme.tertiary, Modifier.weight(1f))
                                    ReportStatCard("Paid Amount", MoneyUtils.formatPaise(salesReport.totalPaidPaise), Teal700, Modifier.weight(1f))
                                }
                            }
                            item {
                                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                                    ReportStatCard("Pending Dues", MoneyUtils.formatPaise(salesReport.totalPendingPaise), StockRed, Modifier.weight(1f))
                                    ReportStatCard("Returns", MoneyUtils.formatPaise(salesReport.totalReturnedPaise), StockOrange, Modifier.weight(1f))
                                }
                            }
                        }

                        1 -> {
                            // Profit Report
                            item {
                                ReportStatCard("Net Profit", MoneyUtils.formatPaise(profitReport.netProfitPaise), Teal700)
                            }
                            item {
                                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                                    ReportStatCard("Gross Sales", MoneyUtils.formatPaise(profitReport.grossSalesPaise), MaterialTheme.colorScheme.primary, Modifier.weight(1f))
                                    ReportStatCard("Cost of Goods (COGS)", MoneyUtils.formatPaise(profitReport.costOfGoodsSoldPaise), StockOrange, Modifier.weight(1f))
                                }
                            }
                            item {
                                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                                    ReportStatCard("Gross Profit", MoneyUtils.formatPaise(profitReport.grossProfitPaise), Teal700, Modifier.weight(1f))
                                    ReportStatCard("Refund Deductions", MoneyUtils.formatPaise(profitReport.returnedAmountPaise), StockRed, Modifier.weight(1f))
                                }
                            }
                        }

                        2 -> {
                            // Stock Report
                            item {
                                ReportStatCard("Stock Cost Value", MoneyUtils.formatPaise(stockReport.stockCostValuePaise), MaterialTheme.colorScheme.primary)
                            }
                            item {
                                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                                    ReportStatCard("Retail Value", MoneyUtils.formatPaise(stockReport.stockRetailValuePaise), Teal700, Modifier.weight(1f))
                                    ReportStatCard("Potential Profit", MoneyUtils.formatPaise(stockReport.potentialProfitPaise), MaterialTheme.colorScheme.tertiary, Modifier.weight(1f))
                                }
                            }
                            item {
                                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                                    ReportStatCard("Total Products", "${stockReport.totalProductsCount}", MaterialTheme.colorScheme.onSurface, Modifier.weight(1f))
                                    ReportStatCard("Total Stock Qty", "${stockReport.totalStockQuantity}", MaterialTheme.colorScheme.onSurface, Modifier.weight(1f))
                                }
                            }
                            item {
                                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                                    ReportStatCard("Low Stock Items", "${stockReport.lowStockCount}", StockOrange, Modifier.weight(1f))
                                    ReportStatCard("Out of Stock Items", "${stockReport.outOfStockCount}", StockRed, Modifier.weight(1f))
                                }
                            }
                        }

                        3 -> {
                            // Customer Dues Report
                            item {
                                val totalDue = customersWithDues.sumOf { it.outstandingDuePaise }
                                ReportStatCard("Total Outstanding Dues", MoneyUtils.formatPaise(totalDue), StockRed)
                            }
                            item {
                                Text("Customers with Pending Dues (${customersWithDues.size})", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            }
                            if (customersWithDues.isEmpty()) {
                                item {
                                    EmptyState(icon = Icons.Filled.BarChart, title = "No pending dues", subtitle = "All registered customer accounts are fully paid!")
                                }
                            } else {
                                items(customersWithDues, key = { it.id }) { customer ->
                                    Card(
                                        shape = RoundedCornerShape(12.dp),
                                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Row(
                                            modifier = Modifier.padding(16.dp).fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Column {
                                                Text(customer.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                                                Text(customer.mobileNumber, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                            }
                                            Text(MoneyUtils.formatPaise(customer.outstandingDuePaise), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = StockRed)
                                        }
                                    }
                                }
                            }
                        }

                        4 -> {
                            // Best Sellers
                            item {
                                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Text("Rank By Metric", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        FilterChip(
                                            selected = uiState.bestSellerMetric == BestSellerMetric.QUANTITY,
                                            onClick = { viewModel.setBestSellerMetric(BestSellerMetric.QUANTITY) },
                                            label = { Text("Quantity") }
                                        )
                                        FilterChip(
                                            selected = uiState.bestSellerMetric == BestSellerMetric.REVENUE,
                                            onClick = { viewModel.setBestSellerMetric(BestSellerMetric.REVENUE) },
                                            label = { Text("Revenue") }
                                        )
                                        FilterChip(
                                            selected = uiState.bestSellerMetric == BestSellerMetric.PROFIT,
                                            onClick = { viewModel.setBestSellerMetric(BestSellerMetric.PROFIT) },
                                            label = { Text("Profit") }
                                        )
                                    }

                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text("Limit", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        listOf(5, 10, 20).forEach { limit ->
                                            FilterChip(
                                                selected = uiState.bestSellerLimit == limit,
                                                onClick = { viewModel.setBestSellerLimit(limit) },
                                                label = { Text("Top $limit") }
                                            )
                                        }
                                    }
                                }
                            }

                            if (bestSellers.isEmpty()) {
                                item {
                                    EmptyState(icon = Icons.Filled.BarChart, title = "No best seller data", subtitle = "No sales recorded for the selected period.")
                                }
                            } else {
                                items(bestSellers.withIndex().toList()) { (index, item) ->
                                    Card(
                                        shape = RoundedCornerShape(12.dp),
                                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Row(
                                            modifier = Modifier.padding(16.dp).fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Surface(
                                                    color = MaterialTheme.colorScheme.primaryContainer,
                                                    shape = RoundedCornerShape(8.dp)
                                                ) {
                                                    Text(
                                                        text = "#${index + 1}",
                                                        style = MaterialTheme.typography.titleSmall,
                                                        fontWeight = FontWeight.Bold,
                                                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                                                    )
                                                }

                                                Spacer(modifier = Modifier.width(12.dp))

                                                Column {
                                                    Text(item.productNameSnapshot, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                                                    Text("Qty Sold: ${item.totalQuantitySold}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                                }
                                            }

                                            Column(horizontalAlignment = Alignment.End) {
                                                Text(MoneyUtils.formatPaise(item.totalRevenuePaise), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                                                Text("Profit: ${MoneyUtils.formatPaise(item.totalProfitPaise)}", style = MaterialTheme.typography.labelSmall, color = Teal700, fontWeight = FontWeight.SemiBold)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ReportStatCard(
    title: String,
    value: String,
    color: androidx.compose.ui.graphics.Color,
    modifier: Modifier = Modifier
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        modifier = modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(4.dp))
            Text(value, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = color)
        }
    }
}
