package com.shopzo.app.core.model

/**
 * Reasons for manual stock adjustments.
 */
enum class AdjustmentReason(val displayName: String) {
    DAMAGED_PRODUCT("Damaged Product"),
    EXPIRED_PRODUCT("Expired Product"),
    SPILL_LOSS("Spill / Loss"),
    STOCK_COUNT_CORRECTION("Stock Count Correction"),
    INVENTORY_AUDIT_ADJUSTMENT("Inventory Audit Adjustment"),
    OTHER("Other")
}
