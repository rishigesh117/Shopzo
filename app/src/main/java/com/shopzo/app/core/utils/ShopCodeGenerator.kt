package com.shopzo.app.core.utils

/**
 * Generates unique Shop Codes in the format SZ-XXXXXX.
 * Example: SZ-ABC123, SZ-K7M4P2
 */
object ShopCodeGenerator {

    private val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    /**
     * Generates a random shop code in format SZ-XXXXXX.
     */
    fun generate(): String {
        val code = (1..6).map { chars.random() }.joinToString("")
        return "SZ-$code"
    }
}
