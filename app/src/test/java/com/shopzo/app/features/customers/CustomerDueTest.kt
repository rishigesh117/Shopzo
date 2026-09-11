package com.shopzo.app.features.customers

import org.junit.Assert.assertEquals
import org.junit.Test

class CustomerDueTest {

    @Test
    fun testCustomerDueCalculationOnPartialPayment() {
        val billTotal = 80000L // ₹800.00
        val paidAmount = 50000L // ₹500.00
        val initialDue = billTotal - paidAmount

        assertEquals(30000L, initialDue) // ₹300.00

        val customerPayment = 20000L // ₹200.00 payment
        val updatedDue = initialDue - customerPayment

        assertEquals(10000L, updatedDue) // ₹100.00
    }
}
