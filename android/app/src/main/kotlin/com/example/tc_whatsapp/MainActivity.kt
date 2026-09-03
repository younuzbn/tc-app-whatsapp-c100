package com.example.tc_whatsapp

import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Base64
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val imageChannelName = "win_app/image_picker"
    private val upiChannelName = "win_app/upi"
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, imageChannelName)
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
                    "saveImage" -> {
                        val filename = call.argument<String>("filename") ?: "win-app-upi-qr.jpg"
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("INVALID", "Missing image data", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(saveImageToGallery(bytes, filename))
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, upiChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listApps" -> {
                        try {
                            result.success(listInstalledUpiApps())
                        } catch (e: Exception) {
                            result.error("UPI_LIST_FAILED", e.message, null)
                        }
                    }
                    "launch" -> {
                        val uri = call.argument<String>("uri") ?: ""
                        val packageName = call.argument<String>("packageName") ?: ""
                        if (uri.isBlank()) {
                            result.error("INVALID", "Missing UPI URI", null)
                            return@setMethodCallHandler
                        }
                        try {
                            launchUpi(uri, packageName)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UPI_LAUNCH_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun listInstalledUpiApps(): List<Map<String, String>> {
        val intent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("upi://pay?pa=example@upi&pn=Payee&am=1.00&cu=INR")
        )
        intent.addCategory(Intent.CATEGORY_DEFAULT)
        val pm = packageManager
        val resolveInfos = queryUpiActivities(pm, intent).ifEmpty {
            queryUpiActivities(pm, Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay")))
        }
        val apps = ArrayList<Map<String, String>>()
        val seen = HashSet<String>()
        for (info in resolveInfos) {
            val packageName = info.activityInfo?.packageName ?: continue
            if (!seen.add(packageName)) continue
            val label = info.loadLabel(pm)?.toString()?.ifBlank { packageName } ?: packageName
            val icon = try {
                drawableToPngBase64(info.loadIcon(pm))
            } catch (_: Exception) {
                ""
            }
            apps.add(
                hashMapOf(
                    "name" to label,
                    "packageName" to packageName,
                    "iconBase64" to icon
                )
            )
        }
        return apps
    }

    private fun queryUpiActivities(
        pm: PackageManager,
        intent: Intent
    ): List<android.content.pm.ResolveInfo> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_ALL.toLong())
            )
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
        }
    }

    private fun launchUpi(uriString: String, packageName: String) {
        fun viewIntent(uri: String): Intent {
            return Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
                addCategory(Intent.CATEGORY_DEFAULT)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (packageName.isNotBlank()) {
                    setPackage(packageName)
                }
            }
        }
        try {
            startActivity(viewIntent(uriString))
        } catch (_: Exception) {
            val fallback = uriString
                .replace("tez://upi/pay?", "upi://pay?")
                .replace("gpay://upi/pay?", "upi://pay?")
            if (fallback == uriString) throw Exception("No UPI app could open this payment")
            startActivity(viewIntent(fallback))
        }
    }

    private fun drawableToPngBase64(drawable: Drawable?): String {
        if (drawable == null) return ""
        val src: Bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val width = drawable.intrinsicWidth.coerceAtLeast(48)
            val height = drawable.intrinsicHeight.coerceAtLeast(48)
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, width, height)
            drawable.draw(canvas)
            bitmap
        }
        val scaled = Bitmap.createScaledBitmap(src, 96, 96, true)
        val stream = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.PNG, 90, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }

    private fun saveImageToGallery(bytes: ByteArray, filename: String): String {
        val mime = if (filename.lowercase().endsWith(".png")) "image/png" else "image/jpeg"
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, filename)
            put(MediaStore.Images.Media.MIME_TYPE, mime)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/WinApp")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: throw Exception("Unable to save QR to gallery")
        resolver.openOutputStream(uri).use { output ->
            requireNotNull(output) { "Unable to write QR image" }
            output.write(bytes)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        }
        return uri.toString()
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
