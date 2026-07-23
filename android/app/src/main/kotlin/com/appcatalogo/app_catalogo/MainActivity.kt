package com.appcatalogo.app_catalogo

import android.content.ClipData
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "app_catalogo/files",
        ).setMethodCallHandler { call, result ->
            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) {
                result.error("invalid_path", "La ruta del PDF no es válida.", null)
                return@setMethodCallHandler
            }
            val file = File(path)
            if (!file.exists()) {
                result.error("missing_file", "El archivo PDF ya no existe.", null)
                return@setMethodCallHandler
            }
            try {
                val uri = createShareablePdfUri(file)
                when (call.method) {
                    "openPdf" -> {
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/pdf")
                            clipData = ClipData.newRawUri("Cotización", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        val chooser = Intent.createChooser(intent, "Ver cotización").apply {
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(chooser)
                    }
                    "sharePdf" -> {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "application/pdf"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            clipData = ClipData.newRawUri("Cotización", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        val chooser = Intent.createChooser(intent, "Compartir cotización").apply {
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(chooser)
                    }
                    else -> {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                }
                result.success(null)
            } catch (error: Exception) {
                result.error("file_action_failed", error.message, null)
            }
        }
    }

    private fun createShareablePdfUri(source: File): Uri {
        val sharedDirectory = File(cacheDir, "shared_pdfs")
        if (!sharedDirectory.exists() && !sharedDirectory.mkdirs()) {
            throw IllegalStateException("No se pudo preparar el PDF para compartir.")
        }
        val safeName = source.name.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val sharedFile = File(sharedDirectory, safeName)
        source.copyTo(sharedFile, overwrite = true)
        return FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            sharedFile,
        )
    }
}
