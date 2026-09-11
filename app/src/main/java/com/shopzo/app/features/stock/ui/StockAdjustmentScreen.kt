package com.shopzo.app.features.stock.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.model.AdjustmentReason

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StockAdjustmentScreen(
    productId: String,
    viewModel: StockViewModel,
    onNavigateBack: () -> Unit
) {
    val focusManager = LocalFocusManager.current
    var reasonExpanded by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Adjust Stock") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(24.dp)
        ) {
            Text("Stock Adjustment", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text("Reduce stock for damaged, expired, or lost items", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(16.dp))

            // Reason Dropdown
            ExposedDropdownMenuBox(expanded = reasonExpanded, onExpandedChange = { reasonExpanded = it }) {
                OutlinedTextField(
                    value = viewModel.selectedReason.displayName,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Reason *") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = reasonExpanded) },
                    modifier = Modifier.fillMaxWidth().menuAnchor(),
                    shape = MaterialTheme.shapes.medium
                )
                ExposedDropdownMenu(expanded = reasonExpanded, onDismissRequest = { reasonExpanded = false }) {
                    AdjustmentReason.entries.forEach { reason ->
                        DropdownMenuItem(
                            text = { Text(reason.displayName) },
                            onClick = { viewModel.selectedReason = reason; reasonExpanded = false }
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = viewModel.adjustQuantity,
                onValueChange = { viewModel.adjustQuantity = it; viewModel.clearError() },
                label = { Text("Quantity to Remove *") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal, imeAction = ImeAction.Next),
                modifier = Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.medium
            )
            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = viewModel.adjustNotes,
                onValueChange = { viewModel.adjustNotes = it },
                label = { Text("Notes (Optional)") },
                maxLines = 3,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { focusManager.clearFocus() }),
                modifier = Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.medium
            )

            AnimatedVisibility(visible = viewModel.errorMessage != null) {
                Text(
                    text = viewModel.errorMessage ?: "",
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.fillMaxWidth().padding(top = 8.dp)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = { viewModel.adjustStock(productId, onSuccess = onNavigateBack) },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = MaterialTheme.shapes.medium,
                enabled = !viewModel.isLoading
            ) {
                if (viewModel.isLoading) {
                    CircularProgressIndicator(Modifier.size(24.dp), MaterialTheme.colorScheme.onPrimary, strokeWidth = 2.dp)
                } else {
                    Text("Adjust Stock", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }
}
