package com.shopzo.app.core.model

/**
 * All granular permissions available in SHOPZO.
 * Owner has FULL_ACCESS which bypasses all permission checks.
 * Staff can be assigned individual permissions.
 *
 * Designed to be scalable — new permissions can be added for Phase 2/3.
 */
enum class Permission(val displayName: String, val group: PermissionGroup) {
    // Billing
    BILLING_CREATE("Create Bills", PermissionGroup.BILLING),
    BILLING_VIEW("View Bills", PermissionGroup.BILLING),

    // Inventory
    INVENTORY_ADD("Add Products", PermissionGroup.INVENTORY),
    INVENTORY_EDIT("Edit Products", PermissionGroup.INVENTORY),
    INVENTORY_DELETE("Delete Products", PermissionGroup.INVENTORY),
    INVENTORY_UPDATE_STOCK("Update Stock", PermissionGroup.INVENTORY),

    // Customers
    CUSTOMERS_VIEW("View Customers", PermissionGroup.CUSTOMERS),
    CUSTOMERS_MANAGE("Manage Customers", PermissionGroup.CUSTOMERS),

    // Payments
    PAYMENTS_VIEW("View Payments", PermissionGroup.PAYMENTS),
    PAYMENTS_RECORD("Record Payments", PermissionGroup.PAYMENTS),

    // Reports
    REPORTS_VIEW("View Reports", PermissionGroup.REPORTS),

    // Team
    TEAM_MANAGE("Manage Staff", PermissionGroup.TEAM),
    TEAM_EDIT_PERMISSIONS("Edit Staff Permissions", PermissionGroup.TEAM),

    // Shop
    SHOP_VIEW_SETTINGS("View Shop Settings", PermissionGroup.SHOP);
}

/**
 * Groups permissions for display in the permissions UI.
 */
enum class PermissionGroup(val displayName: String) {
    BILLING("Billing"),
    INVENTORY("Inventory"),
    CUSTOMERS("Customers"),
    PAYMENTS("Payments"),
    REPORTS("Reports"),
    TEAM("Team"),
    SHOP("Shop")
}
