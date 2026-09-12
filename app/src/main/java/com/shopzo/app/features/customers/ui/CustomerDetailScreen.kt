package com.shopzo.app.features.customers.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Payment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.database.entity.CustomerEntity
import com.shopzo.app.core.model.Permission
import com.shopzo.app.core.ui.components.PermissionGate
import com.shopzo.app.core.ui.theme.StockRed
import com.shopzo.app.core.ui.theme.Teal700
import com.shopzo.app.core.utils.MoneyUtils
import com.shopzo.app.features.billing.ui.BillCard
import com.shopzo.app.features.payments.ui.PaymentViewModel
import com.shopzo.app.features.payments.ui.RecordPaymentDialog
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomerDetailScreen(
    customerId: String,
    viewModel: CustomerViewModel,
    paymentViewModel: PaymentViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToBillDetail: (String) -> Unit
) {
    val shopId by viewModel.shopId.collectAsState()
    val customer by viewModel.getCustomerDetail(customerId).collectAsState(initial = null)
    val bills by viewModel.getCustomerBills(shopId, customerId).collectAsState(initial = emptyList())
    val payments by viewModel.getCustomerPayments(customerId).collectAsState(initial = emptyList())

    var showRecordPaymentDialog by remember { mutableStateOf(false) }
    var showEditDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var selectedTab by remember { mutableStateOf(0) } // 0 = Bills, 1 = Payments

    val dateFormat = remember { SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault()) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(customer?.name ?: "Customer Profile", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (customer != null) {
                        IconButton(onClick = { showEditDialog = true }) {
                            Icon(Icons.Outlined.Edit, contentDescription = "Edit Customer")
                        }
                        IconButton(onClick = { showDeleteDialog = true }) {
                            Icon(Icons.Outlined.Delete, contentDescription = "Delete Customer", tint = MaterialTheme.colorScheme.error)
                        }
                    }
                }
            )
        }
    ) { padding ->
        val currentCustomer = customer
        if (currentCustomer == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            val cust = currentCustomer
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                // Profile & Balance Card
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Person, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(cust.name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        }

                        Spacer(modifier = Modifier.height(6.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Phone, contentDescription = null, modifier = Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(cust.mobileNumber, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }

                        cust.address?.let { addr ->
                            Spacer(modifier = Modifier.height(4.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Filled.Place, contentDescription = null, modifier = Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(addr, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }

                        Divider(modifier = Modifier.padding(vertical = 12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text("Total Purchases", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                Text(MoneyUtils.formatPaise(cust.totalPurchasePaise), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            }

                            Column(horizontalAlignment = Alignment.End) {
                                Text("Outstanding Due", style = MaterialTheme.typography.labelSmall, color = StockRed)
                                Text(MoneyUtils.formatPaise(cust.outstandingDuePaise), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = StockRed)
                            }
                        }

                        if (cust.outstandingDuePaise > 0) {
                            Spacer(modifier = Modifier.height(12.dp))
                            PermissionGate(permission = Permission.PAYMENTS_RECORD) {
                                Button(
                                    onClick = { showRecordPaymentDialog = true },
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Icon(Icons.Filled.Payment, contentDescription = null)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text("Record Payment", fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }

                // Tab Row for Purchase History vs Payment History
                TabRow(selectedTabIndex = selectedTab, modifier = Modifier.fillMaxWidth()) {
                    Tab(selected = selectedTab == 0, onClick = { selectedTab = 0 }, text = { Text("Bills (${bills.size})") })
                    Tab(selected = selectedTab == 1, onClick = { selectedTab = 1 }, text = { Text("Payments (${payments.size})") })
                }

                if (selectedTab == 0) {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        items(bills, key = { it.id }) { bill ->
                            BillCard(bill = bill, onClick = { onNavigateToBillDetail(bill.id) })
                        }
                    }
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        items(payments, key = { it.id }) { payment ->
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
                                        Text(MoneyUtils.formatPaise(payment.amountPaise), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Teal700)
                                        Text("Method: ${payment.paymentMethod}", style = MaterialTheme.typography.bodySmall)
                                    }
                                    Text(dateFormat.format(Date(payment.createdAt)), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showRecordPaymentDialog && customer != null) {
        RecordPaymentDialog(
            bill = null,
            customerId = customerId,
            viewModel = paymentViewModel,
            onDismiss = { showRecordPaymentDialog = false }
        )
    }

    customer?.let { currentCustomer ->
        if (showEditDialog) {
            EditCustomerDialog(
                customer = currentCustomer,
                viewModel = viewModel,
                onDismiss = { showEditDialog = false }
            )
        }

        if (showDeleteDialog) {
            AlertDialog(
                onDismissRequest = { showDeleteDialog = false },
                title = { Text("Delete Customer") },
                text = { Text("Are you sure you want to delete ${currentCustomer.name} (${currentCustomer.mobileNumber})? This action cannot be undone.") },
                confirmButton = {
                    TextButton(
                        onClick = {
                            showDeleteDialog = false
                            viewModel.deleteCustomer(currentCustomer.id) {
                                onNavigateBack()
                            }
                        }
                    ) {
                        Text("Delete", color = MaterialTheme.colorScheme.error)
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showDeleteDialog = false }) {
                        Text("Cancel")
                    }
                }
            )
        }
    }
}
