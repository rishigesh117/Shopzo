package com.shopzo.app.core.utils

import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class ValidationUtilsTest {

    @Test
    fun validateMobileNumber_valid10Digits_returnsNull() {
        assertNull(ValidationUtils.validateMobileNumber("9876543210"))
        assertNull(ValidationUtils.validateMobileNumber("0123456789"))
    }

    @Test
    fun validateMobileNumber_invalidNumbers_returnsError() {
        assertNotNull(ValidationUtils.validateMobileNumber(""))
        assertNotNull(ValidationUtils.validateMobileNumber("123"))
        assertNotNull(ValidationUtils.validateMobileNumber("98765432101"))
        assertNotNull(ValidationUtils.validateMobileNumber("abcdefghij"))
    }

    @Test
    fun validatePassword_lengthChecks() {
        assertNull(ValidationUtils.validatePassword("1234"))
        assertNull(ValidationUtils.validatePassword("securePass123"))
        assertNotNull(ValidationUtils.validatePassword(""))
        assertNotNull(ValidationUtils.validatePassword("123"))
    }

    @Test
    fun validateName_checks() {
        assertNull(ValidationUtils.validateName("Rishi"))
        assertNotNull(ValidationUtils.validateName(""))
        assertNotNull(ValidationUtils.validateName("A"))
    }

    @Test
    fun validatePrice_checks() {
        assertNull(ValidationUtils.validatePrice("100.50"))
        assertNull(ValidationUtils.validatePrice("0"))
        assertNotNull(ValidationUtils.validatePrice("-5"))
        assertNotNull(ValidationUtils.validatePrice(""))
        assertNotNull(ValidationUtils.validatePrice("invalid"))
    }

    @Test
    fun validateQuantity_checks() {
        assertNull(ValidationUtils.validateQuantity("10"))
        assertNull(ValidationUtils.validateQuantity("0.5"))
        assertNotNull(ValidationUtils.validateQuantity("-1"))
        assertNotNull(ValidationUtils.validateQuantity(""))
    }

    @Test
    fun validatePositiveQuantity_requiresStrictlyPositive() {
        assertNull(ValidationUtils.validatePositiveQuantity("5"))
        assertNull(ValidationUtils.validatePositiveQuantity("0.1"))
        assertNotNull(ValidationUtils.validatePositiveQuantity("0"))
        assertNotNull(ValidationUtils.validatePositiveQuantity("-2"))
    }
}
