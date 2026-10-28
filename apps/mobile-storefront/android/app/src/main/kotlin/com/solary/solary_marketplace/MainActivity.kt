package com.solary.solary_marketplace

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Tells Dart whether a Google Maps key was provided; without one the
        // app keeps using the OpenStreetMap picker.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "solary/maps").setMethodCallHandler { call, result ->
            if (call.method == "isConfigured") {
                val info = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                val key = info.metaData?.getString("com.google.android.geo.API_KEY").orEmpty()
                result.success(key.isNotBlank())
            } else {
                result.notImplemented()
            }
        }
    }
}
