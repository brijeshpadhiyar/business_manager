package com.brijesh.stitchflow

import android.content.Context
import android.print.PrintAttributes
import android.print.PrintManager
import android.view.WindowManager
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val WINDOW_SECURITY_CHANNEL = "com.brijesh.stitchflow/window_security"
        private const val REPORT_PRINT_CHANNEL = "com.brijesh.stitchflow/report_print"
    }

    // Hold reference until print manager finishes creating the print document adapter
    private var activePrintWebView: WebView? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WINDOW_SECURITY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setFlagSecure" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    runOnUiThread {
                        if (enabled) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            REPORT_PRINT_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "printHtml" -> {
                    val jobName = call.argument<String>("jobName") ?: "StitchFlow Report"
                    val html = call.argument<String>("html")
                    if (html.isNullOrBlank()) {
                        result.error("INVALID_HTML", "Report HTML content is empty.", null)
                        return@setMethodCallHandler
                    }
                    runOnUiThread {
                        launchWebViewPrint(jobName, html, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchWebViewPrint(
        jobName: String,
        html: String,
        result: MethodChannel.Result,
    ) {
        try {
            activePrintWebView?.destroy()
            activePrintWebView = null

            val webView = WebView(this)
            webView.settings.apply {
                javaScriptEnabled = false
                allowFileAccess = true
                allowContentAccess = false
                defaultTextEncodingName = "UTF-8"
            }

            var callbackDelivered = false
            webView.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    if (callbackDelivered) return
                    callbackDelivered = true
                    try {
                        val printManager =
                            getSystemService(Context.PRINT_SERVICE) as? PrintManager
                        if (printManager == null) {
                            result.error("PRINT_UNAVAILABLE", "Android PrintManager unavailable.", null)
                            return
                        }
                        val adapter = webView.createPrintDocumentAdapter(jobName)
                        val attributes = PrintAttributes.Builder()
                            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
                            .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
                            .build()
                        printManager.print(jobName, adapter, attributes)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("PRINT_FAILED", e.localizedMessage ?: "Failed to print.", null)
                    }
                }

                override fun onReceivedError(
                    view: WebView?,
                    request: WebResourceRequest?,
                    error: WebResourceError?,
                ) {
                    if (!callbackDelivered && (request?.isForMainFrame == true)) {
                        callbackDelivered = true
                        result.error(
                            "WEBVIEW_ERROR",
                            error?.description?.toString() ?: "WebView render failed.",
                            null,
                        )
                    }
                }
            }

            activePrintWebView = webView
            webView.loadDataWithBaseURL(
                "file:///android_asset/",
                html,
                "text/html",
                "UTF-8",
                null,
            )
        } catch (e: Exception) {
            result.error("PRINT_INIT_FAILED", e.localizedMessage ?: "Unable to initialize print.", null)
        }
    }

    override fun onDestroy() {
        activePrintWebView?.destroy()
        activePrintWebView = null
        super.onDestroy()
    }
}
