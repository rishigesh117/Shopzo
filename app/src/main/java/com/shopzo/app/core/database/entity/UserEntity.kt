package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Represents a user (Owner or Staff) in the SHOPZO system.
 * Both owners and staff share this table, differentiated by [role].
 */
@Entity(
    tableName = "users",
    indices = [Index(value = ["mobileNumber"], unique = true)]
)
data class UserEntity(
    @PrimaryKey
    val id: String,                // UUID
    val name: String,
    val mobileNumber: String,
    val passwordHash: String,
    val role: String,              // "OWNER" or "STAFF"
    val shopId: String?,           // null until shop is created (for owners) or linked (for staff)
    val createdAt: Long            // epoch millis
)
