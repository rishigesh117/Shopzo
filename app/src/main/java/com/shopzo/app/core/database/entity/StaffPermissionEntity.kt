package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Represents a single permission granted to a staff user.
 * Many-to-many relationship: one user can have multiple permissions.
 */
@Entity(tableName = "staff_permissions")
data class StaffPermissionEntity(
    @PrimaryKey
    val id: String,                // UUID
    val userId: String,            // references UserEntity.id
    val permission: String,        // Permission enum name
    val shopId: String             // references ShopEntity.id
)
