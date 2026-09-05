package com.taebbong.chungmo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.roundToInt

/**
 * Renders the upcoming-wedding widget from the store HomeWidgetService fills.
 *
 * The D-day is computed here, at render time, so the scheduled midnight
 * updates (and the daily updatePeriodMillis backstop) keep it correct while
 * the app stays closed. A wedding whose calendar day has passed renders the
 * empty state until the app next prunes the store.
 */
class ChungmoWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.chungmo_widget)

            val hasSchedule = widgetData.getBoolean("widget_has_schedule", false)
            val dateMillis =
                (widgetData.all["widget_date_millis"] as? Number)?.toLong() ?: 0L
            val daysLeft = daysUntil(dateMillis)

            if (hasSchedule && daysLeft >= 0) {
                views.setViewVisibility(R.id.widget_content, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                views.setTextViewText(R.id.widget_dday, ddayLabel(daysLeft))
                views.setTextViewText(
                    R.id.widget_couple,
                    widgetData.getString("widget_couple", "") ?: "",
                )
                views.setTextViewText(
                    R.id.widget_date,
                    widgetData.getString("widget_date_text", "") ?: "",
                )
                views.setTextViewText(
                    R.id.widget_location,
                    widgetData.getString("widget_location", "") ?: "",
                )
            } else {
                views.setViewVisibility(R.id.widget_content, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Calendar-day distance from today to the wedding, mirroring Dart's
     * DateExtension.daysLeft: a wedding later today is 0, tomorrow is 1.
     * Rounding absorbs a DST shift between the two local midnights.
     */
    private fun daysUntil(dateMillis: Long): Int {
        val diff = startOfDay(dateMillis) - startOfDay(System.currentTimeMillis())
        return (diff / DAY_MILLIS.toDouble()).roundToInt()
    }

    private fun startOfDay(millis: Long): Long {
        val calendar = java.util.Calendar.getInstance()
        calendar.timeInMillis = millis
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

    private fun ddayLabel(daysLeft: Int): String =
        if (daysLeft == 0) "D-DAY" else "D-$daysLeft"

    companion object {
        private const val DAY_MILLIS = 24 * 60 * 60 * 1000L
    }
}
