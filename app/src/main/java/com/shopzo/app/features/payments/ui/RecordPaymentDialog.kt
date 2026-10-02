package com.shopzo.app.features.payments.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.database.entity.BillEntity
import com.shopzo.app.core.ui.theme.StockOrange
import com.shopzo.app.core.ui.theme.Teal700
import com.shopzo.app.core.utils.MoneyUtils

@Composable
fun RecordPaymentDialog(
    bill: BillEntity?,
    customerId: String?,
    viewModel: PaymentViewModel,
    onDismiss: () -> Unit
) {
    var amountInput by remember {
        mutableStateOf(
            if (bill != null) (bill.pendingAmountPaise / 100.0).toString() else ""
        )
    }
    var paymentMethod by remember { mutableStateOf("CASH") }
    val uiState by viewModel.uiState.collectAsState()

    val receivedDouble = amountInput.toDoubleOrNull() ?: 0.0
    val receivedPaise = (receivedDouble * 100).toLong().coerceAtLeast(0L)

    val targetDuePaise = bill?.pendingAmountPaise
    val changePaise = if (targetDuePaise != null) (receivedPaise - targetDuePaise).coerceAtLeast(0L) else 0L
    val remainingPaise = if (targetDuePaise != null) (targetDuePaise - receivedPaise).coerceAtLeast(0L) else 0L

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Record Payment", fontWeight = FontWeight.Bold) },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                uiState.errorMessage?.let { msg ->
                    Text(msg, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    Spacer(modifier = Modifier.height(8.dp))
                }

                if (bill != null) {
                    Text("Bill #: ${bill.billNumber}", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                    Text("Pending Due: ${MoneyUtils.formatPaise(bill.pendingAmountPaise)}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
                    Spacer(modifier = Modifier.height(12.dp))
                }

                OutlinedTextField(
                    value = amountInput,
                    onValueChange = { amountInput = it },
                    label = { Text("Amount Received (₹) *") },
                    placeholder = { Text("e.g. 10 or 50") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                if (bill != null && receivedDouble > 0) {
                    Spacer(modifier = Modifier.height(8.dp))
                    if (changePaise > 0) {
                        Surface(
                            color = Teal700.copy(alpha = 0.1f),
                            shape = MaterialTheme.shapes.small,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.padding(10.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Change to Give:", style = MaterialTheme.typography.labelSmall, color = Teal700)
                                    Text(MoneyUtils.formatPaise(changePaise), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Teal700)
                                }
                                Text("Bill will be marked fully PAID", style = MaterialTheme.typography.labelSmall, color = Teal700)
                            }
                        }
                    } else if (remainingPaise == 0L) {
                        Surface(
                            color = Teal700.copy(alpha = 0.1f),
                            shape = MaterialTheme.shapes.small,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(10.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("Bill Status:", style = MaterialTheme.typography.labelSmall, color = Teal700)
                                Text("Fully PAID (₹0.00 Due)", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = Teal700)
                            }
                        }
                    } else {
                        Surface(
                            color = StockOrange.copy(alpha = 0.1f),
                            shape = MaterialTheme.shapes.small,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(10.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("Remaining Due:", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.error)
                                Text(MoneyUtils.formatPaise(remainingPaise), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.error)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))
                Text("Payment Method", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("CASH", "UPI", "CARD", "CREDIT").forEach { method ->
                        FilterChip(
                            selected = paymentMethod == method,
                            onClick = { paymentMethod = method },
                            label = { Text(method) }
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val amountDouble = amountInput.toDoubleOrNull() ?: 0.0
                    val amountPaise = (amountDouble * 100).toLong().coerceAtLeast(0L)
                    val targetCustId = customerId ?: bill?.customerId ?: "WALK_IN"

                    viewModel.recordPayment(
                        customerId = targetCustId,
                        billId = bill?.id,
                        amountPaise = amountPaise,
                        paymentMethod = paymentMethod,
                        onSuccess = { onDismiss() }
                    )
                },
                enabled = !uiState.isLoading && (amountInput.toDoubleOrNull() ?: 0.0) > 0
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(18.dp), color = MaterialTheme.colorScheme.onPrimary)
                } else {
                    Text("Save Payment")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
