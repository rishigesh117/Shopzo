package com.shopzo.app.core.utils

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ShopCodeGeneratorTest {

    @Test
    fun generate_matchesExpectedFormat() {
        val code = ShopCodeGenerator.generate()
        assertTrue(code.startsWith("SZ-"))
        assertEquals(9, code.length)
        assertTrue(code.matches(Regex("^SZ-[A-Z0-9]{6}$")))
    }

    @Test
    fun generate_producesDistinctCodes() {
        val codes = (1..50).map { ShopCodeGenerator.generate() }.toSet()
        assertEquals(50, codes.size)
    }
}
