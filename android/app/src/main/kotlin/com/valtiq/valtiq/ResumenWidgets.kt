package com.valtiq.valtiq

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget "Anotar gasto": un botón que abre la ventana de anotar. */
class AnotarWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val intent = Intent(context, AnotarActivity::class.java).addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK,
        )
        val abrir = PendingIntent.getActivity(
            context,
            REQUEST_ANOTAR,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        for (id in appWidgetIds) {
            val vista = RemoteViews(context.packageName, R.layout.widget_anotar)
            vista.setOnClickPendingIntent(R.id.widget_raiz, abrir)
            appWidgetManager.updateAppWidget(id, vista)
        }
    }

    private companion object {
        const val REQUEST_ANOTAR = 4101
    }
}

/** Widget de deudas activas: total, cuántas y las tres más grandes. */
class DeudasWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) = pintarResumen(
        context, appWidgetManager, appWidgetIds, widgetData,
        clave = "deudas", titulo = "Deudas activas", seccion = "deudas",
    )
}

/** Widget de préstamos activos: lo que te deben, cuántos y los mayores. */
class PrestamosWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) = pintarResumen(
        context, appWidgetManager, appWidgetIds, widgetData,
        clave = "prestamos", titulo = "Te deben", seccion = "prestamos",
    )
}

/**
 * Pinta un widget de resumen con los textos que deja Valtiq al abrirse
 * (ver `contenidoWidgetResumen` en lib/services/widgets_service.dart). Si
 * Valtiq nunca se ha abierto desde que se puso el widget, invita a abrirla.
 */
private fun pintarResumen(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    datos: SharedPreferences,
    clave: String,
    titulo: String,
    seccion: String,
) {
    val abrir = HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("valtiq://$seccion"),
    )
    val filas = listOf(
        Triple(R.id.fila_0, R.id.nombre_0, R.id.monto_0),
        Triple(R.id.fila_1, R.id.nombre_1, R.id.monto_1),
        Triple(R.id.fila_2, R.id.nombre_2, R.id.monto_2),
    )
    val total = datos.getString("${clave}_total", null)
    for (id in appWidgetIds) {
        val vista = RemoteViews(context.packageName, R.layout.widget_resumen)
        vista.setTextViewText(R.id.titulo, titulo)
        vista.setTextViewText(R.id.total, total ?: "—")
        vista.setTextViewText(
            R.id.cantidad,
            if (total == null) "Abre Valtiq para ver tus datos"
            else datos.getString("${clave}_cantidad", ""),
        )
        filas.forEachIndexed { i, (fila, nombre, monto) ->
            val n = datos.getString("${clave}_nombre_$i", "") ?: ""
            vista.setViewVisibility(fila, if (n.isEmpty()) View.GONE else View.VISIBLE)
            vista.setTextViewText(nombre, n)
            vista.setTextViewText(monto, datos.getString("${clave}_monto_$i", ""))
        }
        val mas = datos.getString("${clave}_mas", "") ?: ""
        vista.setViewVisibility(R.id.mas, if (mas.isEmpty()) View.GONE else View.VISIBLE)
        vista.setTextViewText(R.id.mas, mas)
        vista.setTextViewText(R.id.actualizado, datos.getString("${clave}_actualizado", ""))
        vista.setOnClickPendingIntent(R.id.widget_raiz, abrir)
        appWidgetManager.updateAppWidget(id, vista)
    }
}
