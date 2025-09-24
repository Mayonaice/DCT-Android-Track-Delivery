package com.dct.tracking.android_tyd

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class SplashActivity : Activity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set fullscreen
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
        
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window.statusBarColor = Color.parseColor("#f8faff")
        window.navigationBarColor = Color.parseColor("#f8faff")
        
        // Create splash layout programmatically
        val mainLayout = LinearLayout(this)
        mainLayout.orientation = LinearLayout.VERTICAL
        mainLayout.gravity = Gravity.CENTER
        mainLayout.setBackgroundColor(Color.parseColor("#f8faff"))
        
        // Create logo (image from assets) - super jumbo size
        val logoView = ImageView(this)
        val logoParams = LinearLayout.LayoutParams(1200, 1200)
        logoParams.setMargins(0, 0, 0, 0)
        logoView.layoutParams = logoParams
        
        // Load splash_screen.png from assets
        try {
            val inputStream = assets.open("splash_screen.png")
            val drawable = android.graphics.drawable.Drawable.createFromStream(inputStream, null)
            logoView.setImageDrawable(drawable)
            logoView.scaleType = ImageView.ScaleType.FIT_CENTER
        } catch (e: Exception) {
            // Fallback to solid color if image not found
            logoView.setBackgroundColor(Color.parseColor("#007bff"))
        }
        
        // Add logo to layout (no text)
        mainLayout.addView(logoView)
        
        // Set content view
        setContentView(mainLayout)
        
        // Navigate to MainActivity after delay
        Handler(Looper.getMainLooper()).postDelayed({
            val intent = Intent(this, MainActivity::class.java)
            startActivity(intent)
            finish()
        }, 2000)
    }
}