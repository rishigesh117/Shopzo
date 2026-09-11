package com.shopzo.app.features.billing.ui

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.utils.MoneyUtils
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReceiptScreen(
    billId: String,
    viewModel: BillsViewModel,
    shopName: String = "SHOPZO Supermarket",
    onNavigateBack: () -> Unit
) {
    val context = LocalContext.current
    val bill by viewModel.getBillDetail(billId).collectAsState(initial = null)
    val items by viewModel.getBillItems(billId).collectAsState(initial = emptyList())

    val dateFormat = remember { SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault()) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Receipt", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    bill?.let { b ->
                        IconButton(onClick = {
                            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                val text = buildString {
                                    appendLine("--- $shopName ---")
                                    appendLine("Bill Number: ${b.billNumber}")
                                    appendLine("Date: ${dateFormat.format(Date(b.createdAt))}")
                                    appendLine("Customer: ${b.customerNameSnapshot}")
                                    appendLine("-------------------------")
                                    items.forEach { i ->
                                        appendLine("${i.productNameSnapshot} x ${i.quantity} ${i.unit} = ${MoneyUtils.formatPaise(i.subtotalPaise)}")
                                    }
                                    appendLine("-------------------------")
                                    appendLine("TOTAL: ${MoneyUtils.formatPaise(b.grandTotalPaise)}")
                                    appendLine("PAID: ${MoneyUtils.formatPaise(b.paidAmountPaise)}")
                                    appendLine("PENDING: ${MoneyUtils.formatPaise(b.pendingAmountPaise)}")
                                    appendLine("Thank you for shopping!")
                                }
                                putExtra(Intent.EXTRA_TEXT, text)
                            }
                            context.startActivity(Intent.createChooser(shareIntent, "Share Receipt"))
                        }) {
                            Icon(Icons.Filled.Share, contentDescription = "Share Receipt")
                        }
                    }
                }
            )
        }
    ) { padding ->
        if (bill == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            val b = bill!!
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Receipt Container Card
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(20.dp)
                    ) {
                        // Header
                        Text("SHOPZO", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
                        Text("Simple. Smart. Sell.", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
                        Text(shopName, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)

                        Spacer(modifier = Modifier.height(12.dp))
                        Text("========================================", style = MaterialTheme.typography.bodySmall, color = Color.Gray, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)

                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Bill #: ${b.billNumber}", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                            Text(dateFormat.format(Date(b.createdAt)), style = MaterialTheme.typography.bodySmall)
                        }
                        if (b.customerNameSnapshot.isNotEmpty() && b.customerNameSnapshot != "Walk-in Customer") {
                            Text("Customer: ${b.customerNameSnapshot} (${b.customerMobileSnapshot})", style = MaterialTheme.typography.bodySmall)
                        }

                        Text("========================================", style = MaterialTheme.typography.bodySmall, color = Color.Gray, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
                        Spacer(modifier = Modifier.height(8.dp))

                        // Items List
                        LazyColumn(
                            modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(items) { item ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(item.productNameSnapshot, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                                        Text("${item.quantity} ${item.unit} @ ${MoneyUtils.formatPaise(item.sellingPricePaise)}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                    Text(MoneyUtils.formatPaise(item.subtotalPaise), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(8.dp))
                        Text("========================================", style = MaterialTheme.typography.bodySmall, color = Color.Gray, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)

                        // Totals
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("TOTAL:", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                                Text(MoneyUtils.formatPaise(b.grandTotalPaise), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            }
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("PAID:", style = MaterialTheme.typography.bodyMedium)
                                Text(MoneyUtils.formatPaise(b.paidAmountPaise), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                            }
                            if (b.pendingAmountPaise > 0) {
                                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                    Text("PENDING DUE:", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.error)
                                    Text(MoneyUtils.formatPaise(b.pendingAmountPaise), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.error)
                                }
                            }
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("STATUS:", style = MaterialTheme.typography.labelMedium)
                                Text(b.paymentStatus, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))
                        Text("Thank you for shopping with us!", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
                    }
                }
            }
        }
    }
}
