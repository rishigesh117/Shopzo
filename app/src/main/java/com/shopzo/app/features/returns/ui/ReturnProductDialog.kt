package com.shopzo.app.features.returns.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.database.entity.BillItemEntity

@Composable
fun ReturnProductDialog(
    billId: String,
    billItem: BillItemEntity,
    viewModel: ReturnsViewModel,
    onDismiss: () -> Unit
) {
    var prevReturned by remember { mutableStateOf(0.0) }
    var qtyInput by remember { mutableStateOf("") }
    var reason by remember { mutableStateOf("") }
    var restoreStock by remember { mutableStateOf(true) }

    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(billItem.id) {
        prevReturned = viewModel.getPreviouslyReturnedQty(billItem.id)
    }

    val availableForReturn = (billItem.quantity - prevReturned).coerceAtLeast(0.0)

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Return Product: ${billItem.productNameSnapshot}") },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                uiState.errorMessage?.let { msg ->
                    Text(msg, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    Spacer(modifier = Modifier.height(8.dp))
                }

                Text("Originally Sold: ${billItem.quantity} ${billItem.unit}", style = MaterialTheme.typography.bodyMedium)
                Text("Previously Returned: $prevReturned ${billItem.unit}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("Max Returnable: $availableForReturn ${billItem.unit}", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = qtyInput,
                    onValueChange = { qtyInput = it },
                    label = { Text("Return Quantity (${billItem.unit}) *") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = reason,
                    onValueChange = { reason = it },
                    label = { Text("Return Reason (Optional)") },
                    placeholder = { Text("e.g., Damaged, Expired, Customer mind change") },
                    singleLine = false,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(12.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Restore to Stock", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                        Text(
                            if (restoreStock) "Stock will automatically increase by returned quantity" else "Damaged/discarded (do not add back to stock)",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    Switch(
                        checked = restoreStock,
                        onCheckedChange = { restoreStock = it }
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val qty = qtyInput.toDoubleOrNull() ?: 0.0
                    viewModel.processReturn(
                        billId = billId,
                        billItemId = billItem.id,
                        quantityToReturn = qty,
                        stockRestored = restoreStock,
                        reason = reason,
                        onSuccess = { onDismiss() }
                    )
                },
                enabled = !uiState.isLoading && (qtyInput.toDoubleOrNull() ?: 0.0) > 0.0 && (qtyInput.toDoubleOrNull() ?: 0.0) <= availableForReturn
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(18.dp), color = MaterialTheme.colorScheme.onPrimary)
                } else {
                    Text("Confirm Return")
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
