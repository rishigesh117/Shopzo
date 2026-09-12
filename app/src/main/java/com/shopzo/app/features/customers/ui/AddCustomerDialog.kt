package com.shopzo.app.features.customers.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.database.entity.CustomerEntity

import com.shopzo.app.core.utils.ValidationUtils

@Composable
fun AddCustomerDialog(
    viewModel: CustomerViewModel,
    onDismiss: () -> Unit,
    onCustomerCreated: (CustomerEntity) -> Unit = {}
) {
    var name by remember { mutableStateOf("") }
    var mobileNumber by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    val uiState by viewModel.uiState.collectAsState()

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add New Customer") },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                uiState.errorMessage?.let { msg ->
                    Text(msg, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    Spacer(modifier = Modifier.height(8.dp))
                }

                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Customer Name *") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = mobileNumber,
                    onValueChange = { mobileNumber = ValidationUtils.filterMobileNumber(it) },
                    label = { Text("Mobile Number *") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    supportingText = { Text("${mobileNumber.length}/10 digits") }
                )
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = address,
                    onValueChange = { address = it },
                    label = { Text("Address (Optional)") },
                    singleLine = false,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    viewModel.createCustomer(name, mobileNumber, address) { customer ->
                        onCustomerCreated(customer)
                        onDismiss()
                    }
                },
                enabled = !uiState.isLoading && name.isNotBlank() && mobileNumber.length == 10
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(18.dp), color = MaterialTheme.colorScheme.onPrimary)
                } else {
                    Text("Save Customer")
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

@Composable
fun EditCustomerDialog(
    customer: CustomerEntity,
    viewModel: CustomerViewModel,
    onDismiss: () -> Unit,
    onCustomerUpdated: (CustomerEntity) -> Unit = {}
) {
    var name by remember { mutableStateOf(customer.name) }
    var mobileNumber by remember { mutableStateOf(customer.mobileNumber) }
    var address by remember { mutableStateOf(customer.address ?: "") }
    val uiState by viewModel.uiState.collectAsState()

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Customer") },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                uiState.errorMessage?.let { msg ->
                    Text(msg, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    Spacer(modifier = Modifier.height(8.dp))
                }

                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Customer Name *") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = mobileNumber,
                    onValueChange = { mobileNumber = ValidationUtils.filterMobileNumber(it) },
                    label = { Text("Mobile Number *") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    supportingText = { Text("${mobileNumber.length}/10 digits") }
                )
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = address,
                    onValueChange = { address = it },
                    label = { Text("Address (Optional)") },
                    singleLine = false,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    viewModel.updateCustomer(customer, name, mobileNumber, address) { updated ->
                        onCustomerUpdated(updated)
                        onDismiss()
                    }
                },
                enabled = !uiState.isLoading && name.isNotBlank() && mobileNumber.length == 10
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(18.dp), color = MaterialTheme.colorScheme.onPrimary)
                } else {
                    Text("Save Changes")
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
