package com.shopzo.app.core.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColorScheme = lightColorScheme(
    primary = Teal700,
    onPrimary = OnTeal,
    primaryContainer = Teal100,
    onPrimaryContainer = Color(0xFF004D40),
    secondary = Amber600,
    onSecondary = OnAmber,
    secondaryContainer = Amber200,
    onSecondaryContainer = Color(0xFF5D4037),
    tertiary = Color(0xFF7C5800),
    onTertiary = Color.White,
    background = Gray50,
    onBackground = Gray900,
    surface = Color.White,
    onSurface = Gray900,
    surfaceVariant = Gray100,
    onSurfaceVariant = Gray700,
    outline = Gray400,
    outlineVariant = Gray200,
    error = ErrorRed,
    onError = Color.White,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002)
)

private val DarkColorScheme = darkColorScheme(
    primary = Teal400,
    onPrimary = Color(0xFF003731),
    primaryContainer = Color(0xFF00695C),
    onPrimaryContainer = Teal200,
    secondary = Amber500,
    onSecondary = Color(0xFF3E2E00),
    secondaryContainer = Color(0xFF5A4300),
    onSecondaryContainer = Amber200,
    tertiary = Color(0xFFFFB74D),
    onTertiary = Color(0xFF442B00),
    background = DarkBackground,
    onBackground = Gray200,
    surface = DarkSurface,
    onSurface = Gray200,
    surfaceVariant = DarkSurfaceVariant,
    onSurfaceVariant = Gray400,
    outline = Gray600,
    outlineVariant = Gray700,
    error = Color(0xFFFF6659),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6)
)

@Composable
fun ShopzoTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.surface.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = ShopzoTypography,
        shapes = ShopzoShapes,
        content = content
    )
}
