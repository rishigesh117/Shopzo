package com.shopzo.app.core.model

/**
 * Stock status derived from current quantity vs minimum stock level.
 */
enum class StockStatus(val displayName: String) {
    IN_STOCK("In Stock"),
    LOW_STOCK("Low Stock"),
    OUT_OF_STOCK("Out of Stock")
}
