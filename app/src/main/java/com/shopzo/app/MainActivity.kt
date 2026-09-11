package com.shopzo.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.shopzo.app.core.ui.theme.ShopzoTheme
import com.shopzo.app.navigation.ShopzoNavGraph

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ShopzoTheme {
                ShopzoNavGraph()
            }
        }
    }
}
