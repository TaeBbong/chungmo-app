package com.taebbong.chungmo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Shader
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Renders the upcoming-wedding widget from the store HomeWidgetService fills.
 *
 * The D-day is computed here, at render time, so the scheduled midnight
 * updates (and the daily updatePeriodMillis backstop) keep it correct while
 * the app stays closed. A wedding whose calendar day has passed renders the
 * empty state until the app next prunes the store.
 *
 * When the store carries an invitation photo it becomes a full-bleed
 * background under a scrim, with all text switched to white; otherwise the
 * flat day/night card renders.
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

            val hasSchedule = widgetData.getBoolean(KEY_HAS_SCHEDULE, false)
            val dateMillis =
                (widgetData.all[KEY_DATE_MILLIS] as? Number)?.toLong() ?: 0L
            val daysLeft = daysUntil(dateMillis)

            if (hasSchedule && daysLeft >= 0) {
                views.setViewVisibility(R.id.widget_content, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                views.setTextViewText(R.id.widget_dday, ddayLabel(daysLeft))
                views.setTextViewText(
                    R.id.widget_couple,
                    widgetData.getString(KEY_COUPLE, "") ?: "",
                )
                views.setTextViewText(
                    R.id.widget_date,
                    widgetData.getString(KEY_DATE_TEXT, "") ?: "",
                )
                // Parsing can leave the location blank; hide the line instead
                // of rendering an empty row.
                val location = widgetData.getString(KEY_LOCATION, "") ?: ""
                views.setTextViewText(R.id.widget_location, location)
                views.setViewVisibility(
                    R.id.widget_location,
                    if (location.isEmpty()) View.GONE else View.VISIBLE,
                )
                applyPhoto(context, appWidgetManager, widgetId, widgetData, views)
            } else {
                views.setViewVisibility(R.id.widget_content, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setViewVisibility(R.id.widget_photo, View.GONE)
                views.setViewVisibility(R.id.widget_scrim, View.GONE)
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Shows the invitation photo background when the store carries one,
     * switching every text to white; keeps the flat card otherwise.
     */
    private fun applyPhoto(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
        views: RemoteViews,
    ) {
        val path = widgetData.getString(KEY_IMAGE, null)
        val photo = path?.let { roundedCover(context, appWidgetManager, widgetId, it) }
        if (photo != null) {
            views.setImageViewBitmap(R.id.widget_photo, photo)
            views.setViewVisibility(R.id.widget_photo, View.VISIBLE)
            views.setViewVisibility(R.id.widget_scrim, View.VISIBLE)
            val white = 0xFFFFFFFF.toInt()
            val whiteDim = 0xE6FFFFFF.toInt()
            views.setTextColor(R.id.widget_dday, white)
            views.setTextColor(R.id.widget_couple, white)
            views.setTextColor(R.id.widget_date, whiteDim)
            views.setTextColor(R.id.widget_location, whiteDim)
        } else {
            views.setViewVisibility(R.id.widget_photo, View.GONE)
            views.setViewVisibility(R.id.widget_scrim, View.GONE)
            // A freshly inflated RemoteViews carries the XML palette, so the
            // flat-card colors need no reset here.
        }
    }

    /**
     * Decodes the stored photo, center-crops it to the widget's aspect ratio
     * and rounds its corners, so `fitXY` shows exactly a cover crop whose
     * corners match the card even on launchers that do not clip widgets.
     */
    private fun roundedCover(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        path: String,
    ): Bitmap? {
        val source = BitmapFactory.decodeFile(path) ?: return null
        val density = context.resources.displayMetrics.density
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
        // Options can be empty right after adding; assume the 2x2 square the
        // widget info declares.
        val minSize = context.resources.getDimensionPixelSize(R.dimen.chungmo_widget_min_size)
        val targetWidth = max((widthDp * density).roundToInt(), minSize)
        val targetHeight = max((heightDp * density).roundToInt(), minSize)

        val scale = max(
            targetWidth.toFloat() / source.width,
            targetHeight.toFloat() / source.height,
        )
        // Never upscale the source: the shader crop below stays sharp and the
        // rounding radius is corrected by the actual output scale.
        val outWidth = min(targetWidth, (source.width * scale).roundToInt())
        val outHeight = min(targetHeight, (source.height * scale).roundToInt())

        val output = Bitmap.createBitmap(outWidth, outHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val shader = BitmapShader(source, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        val matrix = android.graphics.Matrix()
        matrix.setScale(scale, scale)
        matrix.postTranslate(
            (outWidth - source.width * scale) / 2f,
            (outHeight - source.height * scale) / 2f,
        )
        shader.setLocalMatrix(matrix)
        paint.shader = shader
        // Corner radius in bitmap pixels, compensating for fitXY scaling the
        // bitmap up to the widget's real size.
        val radius = context.resources.getDimension(R.dimen.chungmo_widget_corner_radius) *
            (outWidth.toFloat() / targetWidth)
        canvas.drawRoundRect(
            0f, 0f, outWidth.toFloat(), outHeight.toFloat(), radius, radius, paint,
        )
        return output
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

        // Store keys written by HomeWidgetService — keep in sync with
        // lib/core/utils/constants.dart and ChungmoWidget.swift.
        private const val KEY_HAS_SCHEDULE = "widget_has_schedule"
        private const val KEY_COUPLE = "widget_couple"
        private const val KEY_DATE_TEXT = "widget_date_text"
        private const val KEY_LOCATION = "widget_location"
        private const val KEY_DATE_MILLIS = "widget_date_millis"
        private const val KEY_IMAGE = "widget_image"
    }
}
