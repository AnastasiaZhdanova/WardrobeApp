package com.example.wardrobeapp

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles `wardrobe_app/app_lock`. Replies `{status, message}`, see
 * `method_channel_device_auth.dart` for the contract.
 *
 * BIOMETRIC_WEAK | DEVICE_CREDENTIAL is the one combination supported on
 * every API level, and is enough for an app lock (no keys are unlocked).
 */
class AppLockHandler(
    private val activity: FragmentActivity,
) : MethodChannel.MethodCallHandler {
    private val authenticators = BIOMETRIC_WEAK or DEVICE_CREDENTIAL

    // A second call while a prompt is showing would leave the first unanswered.
    private var pending: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "authenticate") {
            result.notImplemented()
            return
        }
        if (pending != null) {
            result.error("busy", "Authentication already in progress.", null)
            return
        }
        val canAuthenticate = BiometricManager.from(activity).canAuthenticate(authenticators)
        if (canAuthenticate != BiometricManager.BIOMETRIC_SUCCESS) {
            result.success(mapOf("status" to "unavailable"))
            return
        }
        pending = result
        val reason = call.argument<String>("reason") ?: "Unlock"
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Unlock WardrobeApp")
            .setSubtitle(reason)
            .setAllowedAuthenticators(authenticators)
            .build()
        BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), callback)
            .authenticate(info)
    }

    private val callback = object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
            reply("success")
        }

        override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
            when (errorCode) {
                BiometricPrompt.ERROR_USER_CANCELED,
                BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                BiometricPrompt.ERROR_CANCELED -> reply("cancelled")
                BiometricPrompt.ERROR_NO_BIOMETRICS,
                BiometricPrompt.ERROR_HW_NOT_PRESENT,
                BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL -> reply("unavailable")
                else -> reply("failed", errString.toString())
            }
        }

        // A single unrecognised finger or face: the prompt stays open and
        // lets the user retry, so there is nothing to report yet.
        override fun onAuthenticationFailed() = Unit
    }

    private fun reply(status: String, message: String? = null) {
        pending?.success(mapOf("status" to status, "message" to message))
        pending = null
    }
}
