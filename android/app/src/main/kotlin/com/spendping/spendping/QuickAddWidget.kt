package com.spendping.spendping

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews

class QuickAddWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget)
            views.setOnClickPendingIntent(R.id.btn_100, tap(context, 10000, 100))
            views.setOnClickPendingIntent(R.id.btn_200, tap(context, 20000, 200))
            views.setOnClickPendingIntent(R.id.btn_500, tap(context, 50000, 500))
            views.setOnClickPendingIntent(R.id.btn_custom, tap(context, null, 1))
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun tap(context: Context, amountMinor: Int?, requestCode: Int): PendingIntent {
        val uri = if (amountMinor == null) {
            Uri.parse("spendping://add")
        } else {
            Uri.parse("spendping://add?amount=$amountMinor")
        }
        val intent = Intent(context, MainActivity::class.java).apply {
            data = uri
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }
}
