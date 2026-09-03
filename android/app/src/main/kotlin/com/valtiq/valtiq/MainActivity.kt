package com.valtiq.valtiq

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (no FlutterActivity) porque local_auth necesita
// una FragmentActivity para mostrar el BiometricPrompt nativo de Android.
class MainActivity : FlutterFragmentActivity()
