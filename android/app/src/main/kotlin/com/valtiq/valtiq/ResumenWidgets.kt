package com.valtiq.valtiq

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import java.time.LocalDate
import java.time.format.DateTimeParseException
import java.time.temporal.ChronoUnit
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

/** Widget de deudas activas: lo que debes hoy, como la tarjeta de Inicio. */
class DeudasWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) = pintarResumen(
        context, appWidgetManager, appWidgetIds, widgetData,
        layout = R.layout.widget_deudas, clave = "deudas", seccion = "deudas",
    )
}

/** Widget de préstamos: lo que te deben hoy, como la tarjeta de Inicio. */
class PrestamosWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) = pintarResumen(
        context, appWidgetManager, appWidgetIds, widgetData,
        layout = R.layout.widget_prestamos, clave = "prestamos", seccion = "prestamos",
    )
}

/**
 * El total de hoy entre los que dejó calculados Valtiq (ver
 * `contenidoWidgetResumen` en lib/services/widgets_service.dart): un
 * renglón por día desde `{clave}_desde`. El interés cambia cada día, así
 * que el widget no repite el número del día en que se abrió Valtiq, sino
 * el que corresponde a hoy. `null` si no hay datos para hoy (Valtiq nunca
 * se abrió, o hace demasiados días).
 */
private fun totalDeHoy(datos: SharedPreferences, clave: String): String? {
    val desde = datos.getString("${clave}_desde", null) ?: return null
    val totales = datos.getString("${clave}_totales", null) ?: return null
    val dias = try {
        ChronoUnit.DAYS.between(LocalDate.parse(desde), LocalDate.now())
    } catch (e: DateTimeParseException) {
        return null
    }
    val lista = totales.split("\n")
    // Si el reloj del celular va para atrás, el primer día es el más cercano.
    val i = dias.coerceAtLeast(0)
    return if (i < lista.size) lista[i.toInt()] else null
}

/** Pinta un widget de resumen y lo deja abriendo Valtiq en su sección. */
private fun pintarResumen(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    datos: SharedPreferences,
    layout: Int,
    clave: String,
    seccion: String,
) {
    val abrir = HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("valtiq://$seccion"),
    )
    val total = totalDeHoy(datos, clave)
    for (id in appWidgetIds) {
        val vista = RemoteViews(context.packageName, layout)
        vista.setTextViewText(R.id.total, total ?: "—")
        vista.setTextViewText(
            R.id.nota,
            if (total == null) context.getString(R.string.widget_abrir_valtiq)
            else datos.getString("${clave}_nota", "") ?: "",
        )
        vista.setOnClickPendingIntent(R.id.widget_raiz, abrir)
        appWidgetManager.updateAppWidget(id, vista)
    }
}
