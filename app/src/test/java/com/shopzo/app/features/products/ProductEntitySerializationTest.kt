package com.shopzo.app.features.products

import com.shopzo.app.core.database.entity.CategoryEntity
import com.shopzo.app.core.database.entity.ProductEntity
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class ProductEntitySerializationTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun testProductEntitySerialization() {
        val product = ProductEntity(
            id = "prod-1",
            name = "Milk bicks",
            categoryId = "cat-1",
            brand = "Britannia",
            buyingPricePaise = 900L,
            sellingPricePaise = 1000L,
            quantity = 50.0,
            unit = "PIECE",
            minStockLevel = 10.0,
            shopId = "shop-1",
            createdAt = 1000L,
            updatedAt = 2000L
        )

        val encoded = json.encodeToString(product)
        assertNotNull(encoded)

        val decoded = json.decodeFromString<ProductEntity>(encoded)
        assertEquals("Milk bicks", decoded.name)
        assertEquals(900L, decoded.buyingPricePaise)
        assertEquals(1000L, decoded.sellingPricePaise)
        assertEquals(50.0, decoded.quantity, 0.001)
        assertEquals("PIECE", decoded.unit)
        assertEquals(10.0, decoded.minStockLevel, 0.001)
        assertEquals("shop-1", decoded.shopId)
    }

    @Test
    fun testCustomerEntitySerialization() {
        val customer = com.shopzo.app.core.database.entity.CustomerEntity(
            id = "cust-1",
            name = "Elumalai",
            mobileNumber = "9677518085",
            address = "Chennai",
            shopId = "shop-1"
        )
        val encoded = json.encodeToString(customer)
        val decoded = json.decodeFromString<com.shopzo.app.core.database.entity.CustomerEntity>(encoded)
        assertEquals("Elumalai", decoded.name)
        assertEquals("9677518085", decoded.mobileNumber)
    }

    @Test
    fun testBillEntitySerialization() {
        val bill = com.shopzo.app.core.database.entity.BillEntity(
            id = "bill-1",
            billNumber = "SZ-0001",
            customerId = "cust-1",
            customerNameSnapshot = "Elumalai",
            customerMobileSnapshot = "9677518085",
            subtotalPaise = 2000L,
            grandTotalPaise = 2000L,
            paidAmountPaise = 2000L,
            pendingAmountPaise = 0L,
            paymentStatus = "PAID",
            shopId = "shop-1"
        )
        val encoded = json.encodeToString(bill)
        val decoded = json.decodeFromString<com.shopzo.app.core.database.entity.BillEntity>(encoded)
        assertEquals("SZ-0001", decoded.billNumber)
        assertEquals(2000L, decoded.grandTotalPaise)
    }

    @Test
    fun testBillItemEntitySerialization() {
        val item = com.shopzo.app.core.database.entity.BillItemEntity(
            id = "item-1",
            billId = "bill-1",
            productId = "prod-1",
            productNameSnapshot = "Milk bicks",
            quantity = 2.0,
            unit = "PIECE",
            sellingPricePaise = 1000L,
            buyingPricePaise = 900L,
            subtotalPaise = 2000L,
            shopId = "shop-1"
        )
        val encoded = json.encodeToString(item)
        val decoded = json.decodeFromString<com.shopzo.app.core.database.entity.BillItemEntity>(encoded)
        assertEquals("Milk bicks", decoded.productNameSnapshot)
        assertEquals(2.0, decoded.quantity, 0.001)
    }

    @Test
    fun testPaymentEntitySerialization() {
        val payment = com.shopzo.app.core.database.entity.PaymentEntity(
            id = "pay-1",
            billId = "bill-1",
            customerId = "cust-1",
            amountPaise = 2000L,
            paymentMethod = "CASH",
            shopId = "shop-1"
        )
        val encoded = json.encodeToString(payment)
        val decoded = json.decodeFromString<com.shopzo.app.core.database.entity.PaymentEntity>(encoded)
        assertEquals(2000L, decoded.amountPaise)
        assertEquals("CASH", decoded.paymentMethod)
    }

    @Test
    fun testStockMovementEntitySerialization() {
        val movement = com.shopzo.app.core.database.entity.StockMovementEntity(
            id = "sm-1",
            productId = "prod-1",
            type = "SALE",
            quantityChange = -2.0,
            previousQuantity = 10.0,
            newQuantity = 8.0,
            buyingPricePaise = null,
            supplier = null,
            reason = null,
            notes = "Bill SZ-0001",
            shopId = "shop-1",
            createdAt = 1000L
        )
        val encoded = json.encodeToString(movement)
        val decoded = json.decodeFromString<com.shopzo.app.core.database.entity.StockMovementEntity>(encoded)
        assertEquals(-2.0, decoded.quantityChange, 0.001)
    }

    @Test
    fun testCategoryEntitySerialization() {
        val category = CategoryEntity(
            id = "cat-1",
            name = "Snacks",
            shopId = "shop-1",
            createdAt = 1000L
        )

        val encoded = json.encodeToString(category)
        val decoded = json.decodeFromString<CategoryEntity>(encoded)
        assertEquals("Snacks", decoded.name)
        assertEquals("cat-1", decoded.id)
    }
}
