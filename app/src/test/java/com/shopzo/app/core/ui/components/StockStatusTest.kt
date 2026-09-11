package com.shopzo.app.core.ui.components

import com.shopzo.app.core.model.StockStatus
import org.junit.Assert.assertEquals
import org.junit.Test

class StockStatusTest {

    @Test
    fun getStockStatus_zeroOrNegative_isOutOfStock() {
        assertEquals(StockStatus.OUT_OF_STOCK, getStockStatus(0.0, 5.0))
        assertEquals(StockStatus.OUT_OF_STOCK, getStockStatus(-1.0, 5.0))
    }

    @Test
    fun getStockStatus_belowOrEqualMinStock_isLowStock() {
        assertEquals(StockStatus.LOW_STOCK, getStockStatus(5.0, 5.0))
        assertEquals(StockStatus.LOW_STOCK, getStockStatus(2.5, 5.0))
        assertEquals(StockStatus.LOW_STOCK, getStockStatus(0.1, 5.0))
    }

    @Test
    fun getStockStatus_aboveMinStock_isInStock() {
        assertEquals(StockStatus.IN_STOCK, getStockStatus(5.1, 5.0))
        assertEquals(StockStatus.IN_STOCK, getStockStatus(100.0, 5.0))
    }
}
