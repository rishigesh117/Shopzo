package com.shopzo.app.core.model

/**
 * Type of stock movement.
 */
enum class StockMovementType(val displayName: String) {
    RESTOCK("Restock"),
    ADJUSTMENT("Adjustment")
}
