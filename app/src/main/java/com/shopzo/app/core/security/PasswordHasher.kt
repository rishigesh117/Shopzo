package com.shopzo.app.core.security

import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/**
 * Password hashing using PBKDF2 with SHA-256.
 *
 * This abstraction can later be replaced or supplemented with
 * backend authentication in Phase 3.
 *
 * Passwords are never stored as plain text.
 */
object PasswordHasher {

    private const val ITERATIONS = 10000
    private const val KEY_LENGTH = 256
    private const val SALT_LENGTH = 16
    private const val ALGORITHM = "PBKDF2WithHmacSHA256"

    /**
     * Hashes a password with a randomly generated salt.
     * Returns a string in format "salt:hash" (both hex-encoded).
     */
    fun hash(password: String): String {
        val salt = generateSalt()
        val hash = pbkdf2(password, salt)
        return "${salt.toHexString()}:${hash.toHexString()}"
    }

    /**
     * Verifies a password against a stored hash string.
     */
    fun verify(password: String, storedHash: String): Boolean {
        val parts = storedHash.split(":")
        if (parts.size != 2) return false
        val salt = parts[0].hexToByteArray()
        val expectedHash = parts[1].hexToByteArray()
        val actualHash = pbkdf2(password, salt)
        return actualHash.contentEquals(expectedHash)
    }

    private fun generateSalt(): ByteArray {
        val salt = ByteArray(SALT_LENGTH)
        SecureRandom().nextBytes(salt)
        return salt
    }

    private fun pbkdf2(password: String, salt: ByteArray): ByteArray {
        val spec = PBEKeySpec(password.toCharArray(), salt, ITERATIONS, KEY_LENGTH)
        val factory = SecretKeyFactory.getInstance(ALGORITHM)
        return factory.generateSecret(spec).encoded
    }

    private fun ByteArray.toHexString(): String =
        joinToString("") { "%02x".format(it) }

    private fun String.hexToByteArray(): ByteArray =
        chunked(2).map { it.toInt(16).toByte() }.toByteArray()
}
