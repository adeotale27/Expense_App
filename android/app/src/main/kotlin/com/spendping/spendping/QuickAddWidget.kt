package com.spendping.spendping

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class QuickAddWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    companion object {
        const val PREFS = "spendping_widget"
        const val KEY_TODAY = "today_total"

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, QuickAddWidget::class.java))
            for (id in ids) {
                manager.updateAppWidget(id, buildViews(context))
            }
        }

        fun publishToday(context: Context, total: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_TODAY, total)
                .apply()
            refresh(context)
        }

        private fun buildViews(context: Context): RemoteViews {
            val today = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_TODAY, "₹0")
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget)
            views.setTextViewText(R.id.txt_today_total, today)
            val open = Intent(context, WidgetComposeActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            var flags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= 23) {
                flags = flags or PendingIntent.FLAG_IMMUTABLE
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(context, 42, open, flags)
            )
            views.setOnClickPendingIntent(
                R.id.btn_add,
                PendingIntent.getActivity(context, 43, open, flags)
            )
            return views
        }
    }
}
