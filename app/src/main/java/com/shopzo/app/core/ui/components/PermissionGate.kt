package com.shopzo.app.core.ui.components

import androidx.compose.runtime.Composable
import com.shopzo.app.core.model.Permission
import com.shopzo.app.core.model.UserRole

/**
 * PermissionGate composable that conditionally renders UI elements based on
 * the user's role and assigned permissions.
 *
 * - [UserRole.OWNER] has full access and always passes any permission check.
 * - [UserRole.STAFF] requires [requiredPermission] to be in [userPermissions].
 * - When permission is granted, [content] is rendered.
 * - When permission is denied, optional [fallback] is rendered (defaults to nothing).
 */
@Composable
fun PermissionGate(
    userRole: UserRole,
    userPermissions: Set<Permission>,
    requiredPermission: Permission,
    fallback: @Composable () -> Unit = {},
    content: @Composable () -> Unit
) {
    val hasPermission = when (userRole) {
        UserRole.OWNER -> true
        UserRole.STAFF -> requiredPermission in userPermissions
    }

    if (hasPermission) {
        content()
    } else {
        fallback()
    }
}

/**
 * Overloaded convenience PermissionGate.
 */
@Composable
fun PermissionGate(
    permission: Permission,
    userRole: UserRole = UserRole.OWNER,
    userPermissions: Set<Permission> = emptySet(),
    fallback: @Composable () -> Unit = {},
    content: @Composable () -> Unit
) {
    PermissionGate(
        userRole = userRole,
        userPermissions = userPermissions,
        requiredPermission = permission,
        fallback = fallback,
        content = content
    )
}

/**
 * Checks if a user has a specific permission based on role and granted set.
 */
fun hasPermission(
    userRole: UserRole,
    userPermissions: Set<Permission>,
    requiredPermission: Permission
): Boolean {
    return when (userRole) {
        UserRole.OWNER -> true
        UserRole.STAFF -> requiredPermission in userPermissions
    }
}
