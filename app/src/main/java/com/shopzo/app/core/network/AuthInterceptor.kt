package com.shopzo.app.core.network

import okhttp3.Interceptor
import okhttp3.Response

class AuthInterceptor(
    private val tokenProvider: () -> String?,
    private val shopIdProvider: () -> String?
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        val builder = originalRequest.newBuilder()

        val token = tokenProvider()
        if (!token.isNullOrEmpty()) {
            builder.addHeader("Authorization", "Bearer $token")
        }

        val shopId = shopIdProvider()
        if (!shopId.isNullOrEmpty()) {
            builder.addHeader("X-Shop-Id", shopId)
        }

        return chain.proceed(builder.build())
    }
}
