package com.spendping.spendping

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
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
            appWidgetManager.updateAppWidget(id, buildViews(context, id))
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TAP) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val amount = intent.getIntExtra(EXTRA_AMOUNT, -1)
            val what = intent.getStringExtra(EXTRA_WHAT)
            if (amount > 0) {
                prefs.edit().putInt(KEY_AMOUNT, amount).apply()
            }
            if (!what.isNullOrBlank()) {
                prefs.edit().putString(KEY_WHAT, what).apply()
            }
            val selectedAmount = prefs.getInt(KEY_AMOUNT, 0)
            val selectedWhat = prefs.getString(KEY_WHAT, null)
            if (selectedAmount > 0 && !selectedWhat.isNullOrBlank()) {
                prefs.edit().remove(KEY_AMOUNT).remove(KEY_WHAT).apply()
                val uri = Uri.parse("spendping://quick?amount=$selectedAmount&what=$selectedWhat")
                val open = Intent(context, MainActivity::class.java).apply {
                    data = uri
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                context.startActivity(open)
            }
            refresh(context)
            return
        }
        super.onReceive(context, intent)
    }

    companion object {
        const val ACTION_TAP = "com.spendping.spendping.WIDGET_TAP"
        const val EXTRA_AMOUNT = "amount"
        const val EXTRA_WHAT = "what"
        const val PREFS = "spendping_widget"
        const val KEY_AMOUNT = "amount"
        const val KEY_WHAT = "what"
        const val KEY_TODAY = "today_total"

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, QuickAddWidget::class.java))
            for (id in ids) {
                manager.updateAppWidget(id, buildViews(context, id))
            }
        }

        fun publishToday(context: Context, total: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_TODAY, total)
                .apply()
            refresh(context)
        }

        private fun buildViews(context: Context, widgetId: Int): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val selectedAmount = prefs.getInt(KEY_AMOUNT, 0)
            val selectedWhat = prefs.getString(KEY_WHAT, "")
            val today = prefs.getString(KEY_TODAY, "₹0")
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget)
            views.setTextViewText(R.id.txt_today_total, today)

            bindAmount(context, views, widgetId, R.id.amt_50, 5000, selectedAmount)
            bindAmount(context, views, widgetId, R.id.amt_100, 10000, selectedAmount)
            bindAmount(context, views, widgetId, R.id.amt_200, 20000, selectedAmount)
            bindAmount(context, views, widgetId, R.id.amt_500, 50000, selectedAmount)

            bindWhat(context, views, widgetId, R.id.what_food, "Food", selectedWhat)
            bindWhat(context, views, widgetId, R.id.what_travel, "Travel", selectedWhat)
            bindWhat(context, views, widgetId, R.id.what_other, "Other", selectedWhat)

            val typeIntent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("spendping://add")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(
                R.id.btn_type,
                PendingIntent.getActivity(
                    context,
                    1,
                    typeIntent,
                    pendingFlags()
                )
            )
            return views
        }

        private fun bindAmount(
            context: Context,
            views: RemoteViews,
            widgetId: Int,
            viewId: Int,
            minor: Int,
            selected: Int
        ) {
            views.setInt(
                viewId,
                "setBackgroundResource",
                if (selected == minor) R.drawable.widget_chip_selected else R.drawable.widget_chip
            )
            val intent = Intent(context, QuickAddWidget::class.java).apply {
                action = ACTION_TAP
                putExtra(EXTRA_AMOUNT, minor)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse("spendping://widget/amount/$minor")
            }
            views.setOnClickPendingIntent(
                viewId,
                PendingIntent.getBroadcast(context, 100 + minor, intent, pendingFlags())
            )
        }

        private fun bindWhat(
            context: Context,
            views: RemoteViews,
            widgetId: Int,
            viewId: Int,
            what: String,
            selected: String?
        ) {
            views.setInt(
                viewId,
                "setBackgroundResource",
                if (selected == what) R.drawable.widget_chip_selected else R.drawable.widget_chip
            )
            val intent = Intent(context, QuickAddWidget::class.java).apply {
                action = ACTION_TAP
                putExtra(EXTRA_WHAT, what)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse("spendping://widget/what/$what")
            }
            views.setOnClickPendingIntent(
                viewId,
                PendingIntent.getBroadcast(context, what.hashCode(), intent, pendingFlags())
            )
        }

        private fun pendingFlags(): Int {
            var flags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= 23) {
                flags = flags or PendingIntent.FLAG_IMMUTABLE
            }
            return flags
        }
    }
}
