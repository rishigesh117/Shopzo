package com.shopzo.app.core.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shopzo.app.core.sync.SyncState

@Composable
fun SyncStatusBadge(
    state: SyncState,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    val (bgColor, dotColor, text) = when (state) {
        SyncState.SYNCED -> Triple(Color(0xFFE8F5E9), Color(0xFF2E7D32), "Synced")
        SyncState.SYNCING -> Triple(Color(0xFFE3F2FD), Color(0xFF1976D2), "Syncing...")
        SyncState.OFFLINE -> Triple(Color(0xFFFFF3E0), Color(0xFFE65100), "Offline")
        SyncState.ERROR -> Triple(Color(0xFFFFEBEE), Color(0xFFC62828), "Sync Error")
    }

    val animatedDotColor by animateColorAsState(targetValue = dotColor, label = "syncDotColor")

    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(animatedDotColor)
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
            fontWeight = FontWeight.Medium,
            color = dotColor
        )
    }
}
