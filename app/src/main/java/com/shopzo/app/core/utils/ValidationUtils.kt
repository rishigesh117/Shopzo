package com.shopzo.app.core.utils

/**
 * Input validation utilities for SHOPZO forms.
 * Returns user-friendly error messages.
 */
object ValidationUtils {

    fun validateMobileNumber(mobile: String): String? {
        val trimmed = mobile.trim()
        if (trimmed.isEmpty()) return "Mobile number is required."
        if (!trimmed.matches(Regex("^[0-9]{10}$"))) return "Enter a valid 10-digit mobile number."
        return null
    }

    fun validatePassword(password: String): String? {
        if (password.isEmpty()) return "Password is required."
        if (password.length < 4) return "Password must be at least 4 characters."
        return null
    }

    fun validateName(name: String, fieldName: String = "Name"): String? {
        if (name.trim().isEmpty()) return "$fieldName is required."
        if (name.trim().length < 2) return "$fieldName must be at least 2 characters."
        return null
    }

    fun validateProductName(name: String): String? {
        if (name.trim().isEmpty()) return "Product name is required."
        return null
    }

    fun validatePrice(price: String, fieldName: String = "Price"): String? {
        if (price.trim().isEmpty()) return "$fieldName is required."
        val amount = price.trim().toDoubleOrNull()
        if (amount == null || amount < 0) return "Enter a valid $fieldName."
        return null
    }

    fun validateQuantity(quantity: String): String? {
        if (quantity.trim().isEmpty()) return "Quantity is required."
        val qty = quantity.trim().toDoubleOrNull()
        if (qty == null || qty < 0) return "Enter a valid quantity."
        return null
    }

    fun validatePositiveQuantity(quantity: String): String? {
        if (quantity.trim().isEmpty()) return "Quantity is required."
        val qty = quantity.trim().toDoubleOrNull()
        if (qty == null || qty <= 0) return "Enter a quantity greater than 0."
        return null
    }

    fun validateMinStockLevel(level: String): String? {
        if (level.trim().isEmpty()) return "Minimum stock level is required."
        val lvl = level.trim().toDoubleOrNull()
        if (lvl == null || lvl < 0) return "Enter a valid minimum stock level."
        return null
    }

    fun validateShopName(name: String): String? {
        if (name.trim().isEmpty()) return "Shop name is required."
        if (name.trim().length < 2) return "Shop name must be at least 2 characters."
        return null
    }

    fun validateCategoryName(name: String): String? {
        if (name.trim().isEmpty()) return "Category name is required."
        return null
    }
}
