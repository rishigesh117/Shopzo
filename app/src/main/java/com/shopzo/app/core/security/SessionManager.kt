package com.shopzo.app.core.security

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.shopzo.app.core.model.UserRole
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking

private val Context.dataStore by preferencesDataStore(name = "shopzo_session")

/**
 * Manages the current user session using DataStore Preferences.
 * Stores userId, shopId, role, and auth JWT token for the logged-in user.
 */
class SessionManager(private val context: Context) {

    companion object {
        private val KEY_USER_ID = stringPreferencesKey("user_id")
        private val KEY_SHOP_ID = stringPreferencesKey("shop_id")
        private val KEY_USER_ROLE = stringPreferencesKey("user_role")
        private val KEY_USER_NAME = stringPreferencesKey("user_name")
        private val KEY_AUTH_TOKEN = stringPreferencesKey("auth_token")
    }

    data class Session(
        val userId: String,
        val shopId: String,
        val userRole: UserRole,
        val userName: String,
        val authToken: String? = null
    )

    val sessionFlow: Flow<Session?> = context.dataStore.data.map { prefs ->
        val userId = prefs[KEY_USER_ID] ?: return@map null
        val shopId = prefs[KEY_SHOP_ID] ?: return@map null
        val role = prefs[KEY_USER_ROLE]?.let {
            try { UserRole.valueOf(it) } catch (_: Exception) { null }
        } ?: return@map null
        val userName = prefs[KEY_USER_NAME] ?: ""
        val token = prefs[KEY_AUTH_TOKEN]
        Session(userId, shopId, role, userName, token)
    }

    suspend fun saveSession(userId: String, shopId: String, role: UserRole, userName: String, token: String? = null) {
        context.dataStore.edit { prefs ->
            prefs[KEY_USER_ID] = userId
            prefs[KEY_SHOP_ID] = shopId
            prefs[KEY_USER_ROLE] = role.name
            prefs[KEY_USER_NAME] = userName
            if (token != null) {
                prefs[KEY_AUTH_TOKEN] = token
            }
        }
    }

    suspend fun saveAuthToken(token: String) {
        context.dataStore.edit { prefs ->
            prefs[KEY_AUTH_TOKEN] = token
        }
    }

    fun getAuthToken(): String? = runBlocking {
        context.dataStore.data.map { it[KEY_AUTH_TOKEN] }.firstOrNull()
    }

    fun getCurrentShopId(): String? = runBlocking {
        context.dataStore.data.map { it[KEY_SHOP_ID] }.firstOrNull()
    }

    suspend fun updateShopId(shopId: String) {
        context.dataStore.edit { prefs ->
            prefs[KEY_SHOP_ID] = shopId
        }
    }

    suspend fun clearSession() {
        context.dataStore.edit { it.clear() }
    }
}
