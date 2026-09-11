package com.shopzo.app.features.billing.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Payment
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Undo
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.database.entity.BillEntity
import com.shopzo.app.core.database.entity.BillItemEntity
import com.shopzo.app.core.model.Permission
import com.shopzo.app.core.ui.components.PermissionGate
import com.shopzo.app.core.ui.theme.StockOrange
import com.shopzo.app.core.ui.theme.StockRed
import com.shopzo.app.core.ui.theme.Teal700
import com.shopzo.app.core.utils.MoneyUtils
import com.shopzo.app.features.payments.ui.PaymentViewModel
import com.shopzo.app.features.payments.ui.RecordPaymentDialog
import com.shopzo.app.features.returns.ui.ReturnProductDialog
import com.shopzo.app.features.returns.ui.ReturnsViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BillDetailScreen(
    billId: String,
    viewModel: BillsViewModel,
    paymentViewModel: PaymentViewModel,
    returnsViewModel: ReturnsViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToReceipt: (String) -> Unit
) {
    val bill by viewModel.getBillDetail(billId).collectAsState(initial = null)
    val items by viewModel.getBillItems(billId).collectAsState(initial = emptyList())
    val paymentHistory by viewModel.getPaymentHistory(billId).collectAsState(initial = emptyList())
    val returnHistory by viewModel.getReturnHistory(billId).collectAsState(initial = emptyList())

    var showRecordPaymentDialog by remember { mutableStateOf(false) }
    var selectedItemForReturn by remember { mutableStateOf<BillItemEntity?>(null) }

    val dateFormat = remember { SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault()) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(bill?.billNumber ?: "Bill Details", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    bill?.let {
                        IconButton(onClick = { onNavigateToReceipt(billId) }) {
                            Icon(Icons.Filled.Receipt, contentDescription = "View Receipt", tint = MaterialTheme.colorScheme.primary)
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
            val currentBill = bill!!
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Header Card
                item {
                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(currentBill.billNumber, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)

                                val (statusText, statusBg, statusFg) = when (currentBill.paymentStatus) {
                                    "PAID" -> Triple("PAID", Teal700.copy(alpha = 0.15f), Teal700)
                                    "PARTIALLY_PAID" -> Triple("PARTIALLY PAID", StockOrange.copy(alpha = 0.15f), StockOrange)
                                    else -> Triple("PENDING", StockRed.copy(alpha = 0.15f), StockRed)
                                }
                                Surface(color = statusBg, shape = RoundedCornerShape(8.dp)) {
                                    Text(
                                        text = statusText,
                                        style = MaterialTheme.typography.labelSmall,
                                        fontWeight = FontWeight.Bold,
                                        color = statusFg,
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(8.dp))
                            Text("Customer: ${currentBill.customerNameSnapshot}", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                            if (currentBill.customerMobileSnapshot.isNotEmpty()) {
                                Text("Mobile: ${currentBill.customerMobileSnapshot}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            Text("Date & Time: ${dateFormat.format(Date(currentBill.createdAt))}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }

                // Action Buttons Row
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        if (currentBill.pendingAmountPaise > 0) {
                            PermissionGate(permission = Permission.PAYMENTS_RECORD) {
                                Button(
                                    onClick = { showRecordPaymentDialog = true },
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Icon(Icons.Filled.Payment, contentDescription = null)
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Record Payment")
                                }
                            }
                        }

                        OutlinedButton(
                            onClick = { onNavigateToReceipt(billId) },
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Filled.Receipt, contentDescription = null)
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Receipt")
                        }
                    }
                }

                // Items List
                item {
                    Text("Products Sold", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                }

                items(items) { item ->
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(item.productNameSnapshot, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                                    Text(
                                        "${item.quantity} ${item.unit} × ${MoneyUtils.formatPaise(item.sellingPricePaise)}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }

                                Text(
                                    MoneyUtils.formatPaise(item.subtotalPaise),
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }

                            Spacer(modifier = Modifier.height(4.dp))

                            // Return item button
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                                TextButton(
                                    onClick = { selectedItemForReturn = item },
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Icon(Icons.Filled.Undo, contentDescription = null, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Return Item", style = MaterialTheme.typography.labelMedium)
                                }
                            }
                        }
                    }
                }

                // Totals Breakdown
                item {
                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("Grand Total:", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                                Text(MoneyUtils.formatPaise(currentBill.grandTotalPaise), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            }
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("Paid Amount:", style = MaterialTheme.typography.bodyMedium, color = Teal700, fontWeight = FontWeight.SemiBold)
                                Text(MoneyUtils.formatPaise(currentBill.paidAmountPaise), style = MaterialTheme.typography.bodyMedium, color = Teal700, fontWeight = FontWeight.SemiBold)
                            }
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("Pending Due:", style = MaterialTheme.typography.bodyMedium, color = StockRed, fontWeight = FontWeight.SemiBold)
                                Text(MoneyUtils.formatPaise(currentBill.pendingAmountPaise), style = MaterialTheme.typography.bodyMedium, color = StockRed, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }
                }

                // Payment History Section
                if (paymentHistory.isNotEmpty()) {
                    item {
                        Text("Payment History", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    }

                    items(paymentHistory) { payment ->
                        Card(
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp).fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(MoneyUtils.formatPaise(payment.amountPaise), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = Teal700)
                                    Text("Method: ${payment.paymentMethod}", style = MaterialTheme.typography.bodySmall)
                                }
                                Text(dateFormat.format(Date(payment.createdAt)), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }

                // Return History Section
                if (returnHistory.isNotEmpty()) {
                    item {
                        Text("Return History", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    }

                    items(returnHistory) { ret ->
                        Card(
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = StockOrange.copy(alpha = 0.1f)),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                    Text("Qty Returned: ${ret.quantityReturned}", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                                    Text("Refund: ${MoneyUtils.formatPaise(ret.refundAmountPaise)}", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = StockRed)
                                }
                                Spacer(modifier = Modifier.height(4.dp))
                                Text("Stock Restored: ${if (ret.stockRestored) "Yes (+${ret.quantityReturned})" else "No"}", style = MaterialTheme.typography.bodySmall)
                                if (ret.reason.isNotEmpty()) {
                                    Text("Reason: ${ret.reason}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                                Text(dateFormat.format(Date(ret.createdAt)), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }
            }
        }
    }

    // Dialogs
    if (showRecordPaymentDialog && bill != null) {
        RecordPaymentDialog(
            bill = bill,
            customerId = bill?.customerId,
            viewModel = paymentViewModel,
            onDismiss = { showRecordPaymentDialog = false }
        )
    }

    selectedItemForReturn?.let { item ->
        ReturnProductDialog(
            billId = billId,
            billItem = item,
            viewModel = returnsViewModel,
            onDismiss = { selectedItemForReturn = null }
        )
    }
}
