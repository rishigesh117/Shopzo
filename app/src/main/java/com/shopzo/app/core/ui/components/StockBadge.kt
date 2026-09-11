package com.shopzo.app.core.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.model.StockStatus
import com.shopzo.app.core.ui.theme.StockGreen
import com.shopzo.app.core.ui.theme.StockOrange
import com.shopzo.app.core.ui.theme.StockRed

/**
 * Visual badge showing stock status with color coding.
 */
@Composable
fun StockBadge(status: StockStatus, modifier: Modifier = Modifier) {
    val backgroundColor by animateColorAsState(
        targetValue = when (status) {
            StockStatus.IN_STOCK -> StockGreen.copy(alpha = 0.15f)
            StockStatus.LOW_STOCK -> StockOrange.copy(alpha = 0.15f)
            StockStatus.OUT_OF_STOCK -> StockRed.copy(alpha = 0.15f)
        },
        label = "stock_badge_bg"
    )
    val textColor = when (status) {
        StockStatus.IN_STOCK -> StockGreen
        StockStatus.LOW_STOCK -> StockOrange
        StockStatus.OUT_OF_STOCK -> StockRed
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(6.dp))
            .background(backgroundColor)
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Text(
            text = status.displayName,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = textColor
        )
    }
}

/**
 * Determines stock status from quantity and minimum stock level.
 */
fun getStockStatus(quantity: Double, minStockLevel: Double): StockStatus {
    return when {
        quantity <= 0 -> StockStatus.OUT_OF_STOCK
        quantity <= minStockLevel -> StockStatus.LOW_STOCK
        else -> StockStatus.IN_STOCK
    }
}
