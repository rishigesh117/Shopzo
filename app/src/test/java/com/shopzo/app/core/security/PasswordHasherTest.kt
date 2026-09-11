package com.shopzo.app.core.security

import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PasswordHasherTest {

    @Test
    fun hash_and_verify_success() {
        val password = "MySecurePassword123"
        val hash = PasswordHasher.hash(password)

        assertTrue(PasswordHasher.verify(password, hash))
    }

    @Test
    fun verify_wrongPassword_returnsFalse() {
        val password = "MySecurePassword123"
        val hash = PasswordHasher.hash(password)

        assertFalse(PasswordHasher.verify("WrongPassword", hash))
    }

    @Test
    fun hash_generatesUniqueSalts() {
        val password = "SamePassword"
        val hash1 = PasswordHasher.hash(password)
        val hash2 = PasswordHasher.hash(password)

        assertNotEquals(hash1, hash2)
        assertTrue(PasswordHasher.verify(password, hash1))
        assertTrue(PasswordHasher.verify(password, hash2))
    }

    @Test
    fun verify_invalidHashFormat_returnsFalse() {
        assertFalse(PasswordHasher.verify("password", "invalidHash"))
    }
}
