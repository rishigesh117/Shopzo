package com.shopzo.app.features.products.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.outlined.Category
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.ui.components.EmptyState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CategoryManagementScreen(
    viewModel: ProductsViewModel,
    onNavigateBack: () -> Unit
) {
    val categories by viewModel.categories.collectAsState()
    var showAddDialog by remember { mutableStateOf(false) }
    var editCategoryId by remember { mutableStateOf<String?>(null) }
    var editCategoryName by remember { mutableStateOf("") }
    var deleteCategoryId by remember { mutableStateOf<String?>(null) }
    var deleteError by remember { mutableStateOf<String?>(null) }

    // Add Category Dialog
    if (showAddDialog) {
        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.addCategory { showAddDialog = false }
                }) { Text("Add") }
            },
            dismissButton = { TextButton(onClick = { showAddDialog = false }) { Text("Cancel") } },
            title = { Text("Add Category") },
            text = {
                Column {
                    OutlinedTextField(
                        value = viewModel.newCategoryName,
                        onValueChange = { viewModel.newCategoryName = it },
                        label = { Text("Category Name") },
                        singleLine = true,
                        shape = MaterialTheme.shapes.medium
                    )
                    viewModel.categoryError?.let { err ->
                        Text(err, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        )
    }

    // Rename Dialog
    if (editCategoryId != null) {
        AlertDialog(
            onDismissRequest = { editCategoryId = null },
            confirmButton = {
                TextButton(onClick = {
                    val cat = categories.find { it.id == editCategoryId }
                    if (cat != null && editCategoryName.isNotBlank()) {
                        viewModel.renameCategory(cat, editCategoryName) { editCategoryId = null }
                    }
                }) { Text("Rename") }
            },
            dismissButton = { TextButton(onClick = { editCategoryId = null }) { Text("Cancel") } },
            title = { Text("Rename Category") },
            text = {
                OutlinedTextField(
                    value = editCategoryName,
                    onValueChange = { editCategoryName = it },
                    label = { Text("New Name") },
                    singleLine = true,
                    shape = MaterialTheme.shapes.medium
                )
            }
        )
    }

    // Delete confirm
    val currentDeleteCatId = deleteCategoryId
    if (currentDeleteCatId != null) {
        AlertDialog(
            onDismissRequest = { deleteCategoryId = null; deleteError = null },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.deleteCategory(currentDeleteCatId) { success ->
                        if (success) { deleteCategoryId = null; deleteError = null }
                        else { deleteError = "Cannot delete: category has active products." }
                    }
                }) { Text("Delete", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { deleteCategoryId = null; deleteError = null }) { Text("Cancel") } },
            title = { Text("Delete Category") },
            text = {
                Column {
                    Text("Are you sure you want to delete this category?")
                    deleteError?.let { err ->
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(err, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Categories") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { showAddDialog = true }) {
                        Icon(Icons.Filled.Add, contentDescription = "Add Category")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { showAddDialog = true }) {
                Icon(Icons.Filled.Add, contentDescription = "Add Category")
            }
        }
    ) { padding ->
        if (categories.isEmpty()) {
            EmptyState(
                icon = Icons.Outlined.Category,
                title = "No Categories",
                subtitle = "Tap + to add a category",
                modifier = Modifier.padding(padding)
            )
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(categories, key = { it.id }) { category ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.medium,
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = category.name,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Medium,
                                modifier = Modifier.weight(1f)
                            )
                            IconButton(onClick = {
                                editCategoryId = category.id
                                editCategoryName = category.name
                            }) {
                                Icon(Icons.Filled.Edit, contentDescription = "Rename", modifier = Modifier.size(20.dp))
                            }
                            IconButton(onClick = { deleteCategoryId = category.id }) {
                                Icon(Icons.Filled.Delete, contentDescription = "Delete", tint = MaterialTheme.colorScheme.error, modifier = Modifier.size(20.dp))
                            }
                        }
                    }
                }
            }
        }
    }
}
