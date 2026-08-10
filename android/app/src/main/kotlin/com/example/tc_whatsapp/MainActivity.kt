package com.example.tc_whatsapp

import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.activity.result.contract.ActivityResultContracts
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "win_app/image_picker"
    private var pendingResult: MethodChannel.Result? = null

    private val pickImageLauncher =
        registerForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
            val result = pendingResult
            pendingResult = null
            if (result == null) return@registerForActivityResult
            if (uri == null) {
                result.success(null)
                return@registerForActivityResult
            }
            try {
                result.success(copyUriToCache(uri))
            } catch (e: Exception) {
                result.error("COPY_FAILED", e.message, null)
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImage" -> {
                        if (pendingResult != null) {
                            result.error("BUSY", "Image picker already open", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        pickImageLauncher.launch("image/*")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun copyUriToCache(uri: Uri): String {
        val resolver = applicationContext.contentResolver
        val mime = resolver.getType(uri) ?: "image/jpeg"
        val ext = when {
            mime.contains("png") -> "png"
            mime.contains("webp") -> "webp"
            else -> "jpg"
        }
        val outFile = File(cacheDir, "wallet_pick_${System.currentTimeMillis()}.$ext")
        resolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Unable to open selected image" }
            FileOutputStream(outFile).use { output -> input.copyTo(output) }
        }
        return outFile.absolutePath
    }
}
