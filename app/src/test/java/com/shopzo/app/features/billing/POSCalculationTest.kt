package com.shopzo.app.features.billing

import com.shopzo.app.features.billing.data.CartItem
import org.junit.Assert.assertEquals
import org.junit.Test

class POSCalculationTest {

    @Test
    fun testCartSubtotalAndGrandTotalCalculation() {
        val rice = CartItem(
            productId = "p1",
            productName = "Rice",
            quantity = 2.0,
            unit = "Kg",
            sellingPricePaise = 6000L, // ₹60.00
            buyingPricePaise = 4500L
        )

        val sugar = CartItem(
            productId = "p2",
            productName = "Sugar",
            quantity = 1.0,
            unit = "Kg",
            sellingPricePaise = 5000L, // ₹50.00
            buyingPricePaise = 4000L
        )

        val milk = CartItem(
            productId = "p3",
            productName = "Milk",
            quantity = 2.0,
            unit = "Litre",
            sellingPricePaise = 3000L, // ₹30.00
            buyingPricePaise = 2500L
        )

        assertEquals(12000L, rice.subtotalPaise)
        assertEquals(5000L, sugar.subtotalPaise)
        assertEquals(6000L, milk.subtotalPaise)

        val cart = listOf(rice, sugar, milk)
        val grandTotal = cart.sumOf { (it.sellingPricePaise * it.quantity).toLong() }
        assertEquals(23000L, grandTotal) // ₹230.00
    }

    @Test
    fun testDecimalQuantityCalculations() {
        val riceFractional = CartItem(
            productId = "p1",
            productName = "Rice",
            quantity = 2.5,
            unit = "Kg",
            sellingPricePaise = 6000L, // ₹60.00 / Kg
            buyingPricePaise = 4500L
        )

        assertEquals(15000L, riceFractional.subtotalPaise) // 2.5 * 60 = 150 -> 15000 paise
    }

    @Test
    fun testPaymentStatusDetermination() {
        val total = 50000L // ₹500.00

        val fullPaidStatus = calculateStatus(total, 50000L)
        assertEquals("PAID", fullPaidStatus)

        val partialPaidStatus = calculateStatus(total, 30000L)
        assertEquals("PARTIALLY_PAID", partialPaidStatus)

        val zeroPaidStatus = calculateStatus(total, 0L)
        assertEquals("PENDING", zeroPaidStatus)
    }

    private fun calculateStatus(grandTotal: Long, paidAmount: Long): String {
        val pending = grandTotal - paidAmount
        return when {
            pending <= 0L -> "PAID"
            paidAmount > 0L -> "PARTIALLY_PAID"
            else -> "PENDING"
        }
    }
}
