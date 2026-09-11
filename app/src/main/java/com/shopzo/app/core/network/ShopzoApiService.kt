package com.shopzo.app.core.network

import com.shopzo.app.core.network.dto.*
import retrofit2.Response
import retrofit2.http.*

interface ShopzoApiService {

    // Auth
    @POST("api/auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>

    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>

    @GET("api/auth/me")
    suspend fun getMe(): Response<UserDto>

    // Shops
    @POST("api/shops")
    suspend fun createShop(@Body request: CreateShopRequest): Response<ShopResponse>

    @GET("api/shops/my-shops")
    suspend fun getMyShops(): Response<MyShopsResponse>

    @GET("api/shops/{shopId}")
    suspend fun getShopById(@Path("shopId") shopId: String): Response<ShopResponse>

    // Staff
    @GET("api/shops/{shopId}/staff")
    suspend fun getStaffList(@Path("shopId") shopId: String): Response<StaffListResponse>

    @POST("api/shops/{shopId}/staff")
    suspend fun addStaff(
        @Path("shopId") shopId: String,
        @Body request: AddStaffRequest
    ): Response<StaffResponse>

    @PUT("api/shops/{shopId}/staff/{staffId}/permissions")
    suspend fun updateStaffPermissions(
        @Path("shopId") shopId: String,
        @Path("staffId") staffId: String,
        @Body request: UpdatePermissionsRequest
    ): Response<Unit>

    @DELETE("api/shops/{shopId}/staff/{staffId}")
    suspend fun deleteStaff(
        @Path("shopId") shopId: String,
        @Path("staffId") staffId: String
    ): Response<Unit>

    // Sync
    @POST("api/sync/push")
    suspend fun pushSync(
        @Header("X-Shop-Id") shopId: String,
        @Body request: SyncPushRequest
    ): Response<SyncPushResponse>

    @GET("api/sync/pull")
    suspend fun pullSync(
        @Header("X-Shop-Id") shopId: String,
        @Query("since") since: Long
    ): Response<SyncPullResponse>
}
