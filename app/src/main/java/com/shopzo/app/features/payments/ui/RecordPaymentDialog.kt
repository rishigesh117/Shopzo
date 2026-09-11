package com.shopzo.app.features.payments.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.database.entity.BillEntity
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

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Record Payment") },
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
                    label = { Text("Payment Amount (₹) *") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

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
                    val amountPaise = (amountDouble * 100).toLong()
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
