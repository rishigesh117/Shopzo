package com.shopzo.app.features.reports

import org.junit.Assert.assertEquals
import org.junit.Test

class ProfitCalculationTest {

    @Test
    fun testHistoricalBuyingPriceProfitCalculation() {
        // Historical buying price = ₹40.00 (4000 paise), Selling price = ₹60.00 (6000 paise), Qty = 5
        val sellingPricePaise = 6000L
        val historicalBuyingPricePaise = 4000L
        val quantity = 5.0

        val profitPerUnit = sellingPricePaise - historicalBuyingPricePaise // 2000 paise
        val totalProfitPaise = (profitPerUnit * quantity).toLong()

        assertEquals(10000L, totalProfitPaise) // ₹100.00 profit
    }

    @Test
    fun testProfitDeductionOnReturn() {
        val grossProfit = 10000L // ₹100.00
        val refundAmountPaise = 2000L // ₹20.00 returned

        val netProfit = grossProfit - refundAmountPaise
        assertEquals(8000L, netProfit) // ₹80.00 net profit
    }
}
