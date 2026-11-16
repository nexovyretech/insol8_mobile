package com.example.insol8_mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // In-app updates (lib/services/app_update_service.dart). Dart downloads the APK into
        // updateDir; this side only reads the installed build, handles the "install unknown
        // apps" permission, and hands the file to Android's package installer.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "insol8/app_update")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "installedBuild" -> result.success(installedBuild())
                        "updateDir" -> result.success(updateDir().absolutePath)
                        "canInstallPackages" -> result.success(canInstallPackages())
                        "openInstallPermissionSettings" -> {
                            openInstallPermissionSettings()
                            result.success(null)
                        }
                        "installApk" -> {
                            installApk(File(call.argument<String>("path")!!))
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("APP_UPDATE_FAILED", e.message, null)
                }
            }
    }

    private fun installedBuild(): Long {
        val info = packageManager.getPackageInfo(packageName, 0)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
    }

    // Must match the cache-path in res/xml/app_update_paths.xml.
    private fun updateDir(): File = File(cacheDir, "updates").apply { mkdirs() }

    private fun canInstallPackages(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()

    private fun openInstallPermissionSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))
        } else {
            @Suppress("DEPRECATION")
            Intent(Settings.ACTION_SECURITY_SETTINGS)
        }
        startActivity(intent)
    }

    private fun installApk(apk: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.appupdate", apk)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
}
