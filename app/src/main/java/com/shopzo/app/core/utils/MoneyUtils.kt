package com.shopzo.app.core.utils

import java.text.NumberFormat
import java.util.Locale

/**
 * Utility object for money operations.
 *
 * SHOPZO stores all monetary values as integer paise (minor units).
 * 1 Rupee = 100 Paise
 * ₹100.50 is stored as 10050
 *
 * This prevents floating-point precision issues and is compatible
 * with future backend synchronization.
 */
object MoneyUtils {

    private val indianLocale = Locale("en", "IN")

    /**
     * Converts a rupee amount string (e.g., "100.50") to paise integer (10050).
     * Returns null if the input is invalid.
     */
    fun rupeesToPaise(rupees: String): Int? {
        val amount = rupees.trim().toDoubleOrNull() ?: return null
        if (amount < 0) return null
        return (amount * 100).toInt()
    }

    /**
     * Converts paise integer/long to formatted rupee string.
     * Example: 10050 → "₹100.50"
     */
    fun paiseToRupeeString(paise: Int): String {
        val rupees = paise / 100.0
        val format = NumberFormat.getCurrencyInstance(indianLocale)
        return format.format(rupees)
    }

    fun paiseToRupeeString(paise: Long): String {
        val rupees = paise / 100.0
        val format = NumberFormat.getCurrencyInstance(indianLocale)
        return format.format(rupees)
    }

    fun formatPaise(paise: Long): String = paiseToRupeeString(paise)

    fun formatPaise(paise: Int): String = paiseToRupeeString(paise)

    /**
     * Converts paise to plain decimal string without currency symbol.
     * Example: 10050 → "100.50"
     */
    fun paiseToDecimalString(paise: Int): String {
        val rupees = paise / 100.0
        return String.format(indianLocale, "%.2f", rupees)
    }

    fun paiseToDecimalString(paise: Long): String {
        val rupees = paise / 100.0
        return String.format(indianLocale, "%.2f", rupees)
    }

    /**
     * Validates if a string represents a valid price.
     */
    fun isValidPrice(price: String): Boolean {
        val amount = price.trim().toDoubleOrNull() ?: return false
        return amount >= 0
    }
}
