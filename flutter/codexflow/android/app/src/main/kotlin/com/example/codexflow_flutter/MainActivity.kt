package com.example.codexflow_flutter

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        persistBaseUrlFromIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        val updated = persistBaseUrlFromIntent(intent)
        setIntent(intent)
        super.onNewIntent(intent)
        if (updated) {
            recreate()
        }
    }

    private fun persistBaseUrlFromIntent(intent: Intent?): Boolean {
        val uri = intent?.data ?: return false
        if (uri.scheme != "codexflow" || uri.host != "setup") {
            return false
        }

        val baseUrl = uri.getQueryParameter("baseUrl")?.trim().orEmpty()
        if (!isAllowedBaseUrl(baseUrl)) {
            return false
        }

        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .edit()
            .putString("flutter.codexflow.baseURL", baseUrl)
            .apply()
        return true
    }

    private fun isAllowedBaseUrl(value: String): Boolean {
        val uri = try {
            Uri.parse(value)
        } catch (_: Exception) {
            return false
        }
        val scheme = uri.scheme ?: return false
        if (scheme != "http" && scheme != "https") {
            return false
        }
        return !uri.host.isNullOrBlank()
    }
}
