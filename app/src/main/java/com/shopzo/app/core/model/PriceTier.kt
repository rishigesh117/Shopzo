package com.shopzo.app.core.model

import kotlinx.serialization.Serializable

@Serializable
data class PriceTier(
    val id: String,
    val name: String,
    val quantity: Double,
    val unit: String,
    val pricePaise: Long,
    val buyingPricePaise: Long = 0L
)
