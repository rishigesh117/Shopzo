package com.shopzo.app.core.utils

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MoneyUtilsTest {

    @Test
    fun rupeesToPaise_validRupees_returnsCorrectPaise() {
        assertEquals(10050, MoneyUtils.rupeesToPaise("100.50"))
        assertEquals(10000, MoneyUtils.rupeesToPaise("100"))
        assertEquals(0, MoneyUtils.rupeesToPaise("0"))
        assertEquals(99, MoneyUtils.rupeesToPaise("0.99"))
        assertEquals(250075, MoneyUtils.rupeesToPaise("2500.75"))
    }

    @Test
    fun rupeesToPaise_withWhitespace_parsesSuccessfully() {
        assertEquals(5000, MoneyUtils.rupeesToPaise("  50  "))
    }

    @Test
    fun rupeesToPaise_invalidInputs_returnsNull() {
        assertNull(MoneyUtils.rupeesToPaise("abc"))
        assertNull(MoneyUtils.rupeesToPaise("-10"))
        assertNull(MoneyUtils.rupeesToPaise(""))
    }

    @Test
    fun paiseToDecimalString_convertsCorrectly() {
        assertEquals("100.50", MoneyUtils.paiseToDecimalString(10050))
        assertEquals("0.00", MoneyUtils.paiseToDecimalString(0))
        assertEquals("0.99", MoneyUtils.paiseToDecimalString(99))
        assertEquals("1234.50", MoneyUtils.paiseToDecimalString(123450))
    }

    @Test
    fun paiseToRupeeString_containsCurrencyFormatting() {
        val result = MoneyUtils.paiseToRupeeString(10050)
        assertNotNull(result)
        assertTrue(result.contains("100.50"))
    }

    @Test
    fun isValidPrice_checksCorrectly() {
        assertTrue(MoneyUtils.isValidPrice("100.50"))
        assertTrue(MoneyUtils.isValidPrice("0"))
        assertFalse(MoneyUtils.isValidPrice("-1"))
        assertFalse(MoneyUtils.isValidPrice("abc"))
        assertFalse(MoneyUtils.isValidPrice(""))
    }
}
