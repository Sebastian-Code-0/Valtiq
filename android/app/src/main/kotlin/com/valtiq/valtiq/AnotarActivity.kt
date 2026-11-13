package com.valtiq.valtiq

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

/**
 * Ventana "Anotar gasto" que abre el widget de la pantalla de inicio.
 *
 * Corre la función `anotarMain` de lib/main.dart (no la app completa), con
 * fondo transparente para que se vea encima de la pantalla de inicio. No
 * pasa por el bloqueo con PIN: solo agrega un gasto y no muestra nada de lo
 * guardado.
 */
class AnotarActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String = "anotarMain"

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent
}
