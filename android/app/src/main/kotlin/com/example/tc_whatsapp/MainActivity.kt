package com.example.tc_whatsapp

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
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
import android.provider.Settings
import android.util.Base64
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val imageChannelName = "win_app/image_picker"
    private val upiChannelName = "win_app/upi"
    private val sessionChannelName = "win_app/session"
    private var pendingResult: MethodChannel.Result? = null
    private val notificationPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { }

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

    private val pickVideoLauncher =
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
                            result.error("BUSY", "Media picker already open", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        pickImageLauncher.launch("image/*")
                    }
                    "pickVideo" -> {
                        if (pendingResult != null) {
                            result.error("BUSY", "Media picker already open", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        pickVideoLauncher.launch("video/*")
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
                    "recognizeText" -> {
                        val path = call.argument<String>("path").orEmpty()
                        if (path.isBlank()) {
                            result.error("INVALID", "Missing image path", null)
                            return@setMethodCallHandler
                        }
                        recognizeText(path, result)
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sessionChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "save" -> {
                        saveSession(call.arguments)
                        result.success(null)
                    }
                    "load" -> result.success(loadSession())
                    "clear" -> {
                        clearSession()
                        result.success(null)
                    }
                    "saveLastPhone" -> {
                        saveLastPhone(call.argument<String>("phone").orEmpty())
                        result.success(null)
                    }
                    "loadLastPhone" -> result.success(loadLastPhone())
                    "savePendingReferral" -> {
                        savePendingReferral(call.argument<String>("code").orEmpty())
                        result.success(null)
                    }
                    "loadPendingReferral" -> result.success(loadPendingReferral())
                    "saveAdminInbox" -> {
                        saveAdminInbox(call.argument<String>("data").orEmpty())
                        result.success(null)
                    }
                    "loadAdminInbox" -> result.success(loadAdminInbox())
                    "requestNotificationPermission" -> {
                        requestNotificationPermission()
                        result.success(null)
                    }
                    "setAppBadge" -> {
                        val count = (call.argument<Number>("count")?.toInt() ?: 0)
                        val title = call.argument<String>("title").orEmpty()
                        val text = call.argument<String>("text").orEmpty()
                        val alert = call.argument<Boolean>("alert") == true
                        setAppBadge(count, title, text, alert)
                        result.success(null)
                    }
                    "getDeviceId" -> result.success(androidDeviceId())
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("UNCHECKED_CAST")
    private fun saveSession(raw: Any?) {
        val prefs = getSharedPreferences(SESSION_PREFS_NAME, MODE_PRIVATE).edit()
        prefs.clear()
        val data = raw as? Map<*, *>
        val token = data?.get("authToken")?.toString().orEmpty()
        if (token.isNotEmpty()) {
            prefs.putString("authToken", token)
            prefs.putString("username", data?.get("username")?.toString().orEmpty())
            prefs.putString("displayPhoneNumber", data?.get("displayPhoneNumber")?.toString().orEmpty())
            prefs.putString("userId", data?.get("userId")?.toString().orEmpty())
            prefs.putString("role", data?.get("role")?.toString().orEmpty())
            prefs.putString("referralCode", data?.get("referralCode")?.toString().orEmpty())
            prefs.putBoolean(
                "isAdmin",
                data?.get("isAdmin") == true || data?.get("isAdmin")?.toString() == "true",
            )
            prefs.putBoolean(
                "phoneVerified",
                data?.get("phoneVerified") == true ||
                    data?.get("phoneVerified")?.toString() == "true",
            )
            prefs.putBoolean(
                "notificationPageOpened",
                data?.get("notificationPageOpened") == true ||
                    data?.get("notificationPageOpened")?.toString() == "true",
            )
            prefs.putString(
                "seenNotificationIds",
                data?.get("seenNotificationIds")?.toString().orEmpty(),
            )
            prefs.commit()
        } else {
            prefs.commit()
        }
    }

    private fun loadSession(): HashMap<String, Any> {
        val prefs = getSharedPreferences(SESSION_PREFS_NAME, MODE_PRIVATE)
        val token = prefs.getString("authToken", "").orEmpty()
        val out = HashMap<String, Any>()
        if (token.isNotEmpty()) {
            out["authToken"] = token
            out["username"] = prefs.getString("username", "").orEmpty()
            out["displayPhoneNumber"] = prefs.getString("displayPhoneNumber", "").orEmpty()
            out["userId"] = prefs.getString("userId", "").orEmpty()
            out["role"] = prefs.getString("role", "").orEmpty()
            out["referralCode"] = prefs.getString("referralCode", "").orEmpty()
            out["isAdmin"] = prefs.getBoolean("isAdmin", false)
            out["phoneVerified"] = prefs.getBoolean("phoneVerified", false)
            out["notificationPageOpened"] = prefs.getBoolean("notificationPageOpened", false)
            out["seenNotificationIds"] = prefs.getString("seenNotificationIds", "").orEmpty()
        }
        return out
    }

    private fun clearSession() {
        getSharedPreferences(SESSION_PREFS_NAME, MODE_PRIVATE).edit().clear().commit()
        setAppBadge(0, "", "", false)
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < 33) return
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
    }

    private fun setAppBadge(count: Int, title: String, text: String, alert: Boolean) {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channelId = "win_app_alerts"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Alerts",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "New entries, results, wins, and other alerts"
                setShowBadge(true)
            }
            manager.createNotificationChannel(channel)
        }
        if (count <= 0) {
            manager.cancel(BADGE_NOTIFICATION_ID)
            return
        }
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val body = text.ifBlank {
            if (count == 1) "1 new alert" else "$count new alerts"
        }
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle(title.ifBlank { "Win App" })
            .setContentText(body)
            .setNumber(count)
            .setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL)
            .setAutoCancel(false)
            .setOngoing(false)
            .setOnlyAlertOnce(!alert)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        manager.notify(BADGE_NOTIFICATION_ID, notification)
    }

    private fun saveAdminInbox(data: String) {
        getSharedPreferences(ADMIN_INBOX_PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putString("data", data)
            .commit()
    }

    private fun loadAdminInbox(): String {
        return getSharedPreferences(ADMIN_INBOX_PREFS_NAME, MODE_PRIVATE)
            .getString("data", "")
            .orEmpty()
    }

    private fun saveLastPhone(phone: String) {
        val digits = phone.filter { it.isDigit() }
        val last10 = if (digits.length >= 10) digits.takeLast(10) else digits
        if (last10.length != 10) return
        getSharedPreferences(LAST_LOGIN_PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putString("phone", last10)
            .commit()
    }

    private fun loadLastPhone(): String {
        return getSharedPreferences(LAST_LOGIN_PREFS_NAME, MODE_PRIVATE)
            .getString("phone", "")
            .orEmpty()
    }

    private fun savePendingReferral(code: String) {
        val value = code.trim().uppercase().filter { it.isLetterOrDigit() }
        if (value.isEmpty()) return
        getSharedPreferences(LAST_LOGIN_PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putString("pendingReferral", value)
            .commit()
    }

    private fun loadPendingReferral(): String {
        return getSharedPreferences(LAST_LOGIN_PREFS_NAME, MODE_PRIVATE)
            .getString("pendingReferral", "")
            .orEmpty()
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

    private fun recognizeText(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists()) {
            result.error("OCR_FAILED", "Image file not found", null)
            return
        }
        try {
            val image = InputImage.fromFilePath(this, Uri.fromFile(file))
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    val items = ArrayList<HashMap<String, Any>>()
                    for (block in visionText.textBlocks) {
                        for (line in block.lines) {
                            for (element in line.elements) {
                                val box = element.boundingBox ?: continue
                                items.add(
                                    hashMapOf(
                                        "text" to element.text,
                                        "left" to box.left,
                                        "top" to box.top,
                                        "right" to box.right,
                                        "bottom" to box.bottom,
                                    )
                                )
                            }
                        }
                    }
                    result.success(items)
                    recognizer.close()
                }
                .addOnFailureListener { error ->
                    recognizer.close()
                    result.error("OCR_FAILED", error.message, null)
                }
        } catch (error: Exception) {
            result.error("OCR_FAILED", error.message, null)
        }
    }

    private fun sniffImageExt(bytes: ByteArray): String? {
        if (bytes.size < 12) return null
        if (bytes[0] == 0xFF.toByte() && bytes[1] == 0xD8.toByte() && bytes[2] == 0xFF.toByte()) {
            return "jpg"
        }
        if (bytes[0] == 0x89.toByte() && bytes[1] == 0x50.toByte() &&
            bytes[2] == 0x4E.toByte() && bytes[3] == 0x47.toByte()
        ) {
            return "png"
        }
        if (bytes[0] == 0x47.toByte() && bytes[1] == 0x49.toByte() && bytes[2] == 0x46.toByte()) {
            return "gif"
        }
        if (bytes[0] == 0x42.toByte() && bytes[1] == 0x4D.toByte()) return "bmp"
        val header = bytes.decodeToString(0, 12)
        if (header.startsWith("RIFF") && header.contains("WEBP")) return "webp"
        return null
    }

    private fun copyUriToCache(uri: Uri): String {
        val resolver = applicationContext.contentResolver
        val mime = resolver.getType(uri) ?: ""
        val guessedExt = when {
            mime.contains("png") -> "png"
            mime.contains("webp") -> "webp"
            mime.contains("gif") -> "gif"
            mime.contains("heic") -> "heic"
            mime.contains("heif") -> "heif"
            mime.contains("bmp") -> "bmp"
            mime.contains("avif") -> "avif"
            mime.contains("quicktime") || mime.contains("mov") -> "mov"
            mime.contains("webm") -> "webm"
            mime.contains("3gpp") || mime.contains("3gp") -> "3gp"
            mime.contains("matroska") || mime.contains("mkv") -> "mkv"
            mime.contains("x-msvideo") || mime.contains("avi") -> "avi"
            mime.contains("mp4") -> "mp4"
            mime.contains("mpeg") -> "mpeg"
            mime.startsWith("video/") -> "mp4"
            mime.startsWith("image/") -> "jpg"
            else -> ""
        }
        val temp = File(cacheDir, "wallet_pick_${System.currentTimeMillis()}.part")
        resolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Unable to open selected image" }
            FileOutputStream(temp).use { output -> input.copyTo(output) }
        }
        val sniffed = temp.inputStream().use { stream ->
            val header = ByteArray(16)
            val read = stream.read(header)
            if (read <= 0) null else sniffImageExt(header.copyOf(read))
        }
        val ext = sniffed ?: guessedExt.ifEmpty { "jpg" }
        val outFile = File(cacheDir, "wallet_pick_${System.currentTimeMillis()}.$ext")
        if (outFile.exists()) outFile.delete()
        temp.renameTo(outFile)
        return outFile.absolutePath
    }

    private fun androidDeviceId(): String {
        return Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID).orEmpty()
    }
}
