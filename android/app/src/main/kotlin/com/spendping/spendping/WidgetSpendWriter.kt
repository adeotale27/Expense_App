package com.spendping.spendping

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

object WidgetSpendWriter {
    const val ENGINE_ID = "spendping"
    private const val INBOX = "widget_inbox.json"

    fun save(context: Context, amountMinor: Int, what: String) {
        bumpToday(context, amountMinor)
        val id = UUID.randomUUID().toString()
        appendInbox(context, id, amountMinor, what)
        val engine = FlutterEngineCache.getInstance().get(ENGINE_ID)
        if (engine != null) {
            Handler(Looper.getMainLooper()).post {
                try {
                    MethodChannel(
                        engine.dartExecutor.binaryMessenger,
                        "spendping/widget"
                    ).invokeMethod(
                        "widgetSpend",
                        hashMapOf(
                            "id" to id,
                            "amountMinor" to amountMinor,
                            "what" to what
                        )
                    )
                } catch (_: Exception) {
                }
            }
        }
        val major = amountMinor / 100
        Toast.makeText(context, "Saved ₹$major", Toast.LENGTH_SHORT).show()
        QuickAddWidget.refresh(context)
    }

    fun drainInbox(context: Context): ArrayList<HashMap<String, Any>> {
        val file = File(context.filesDir, INBOX)
        val out = ArrayList<HashMap<String, Any>>()
        if (!file.exists()) return out
        try {
            val arr = JSONArray(file.readText())
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                out.add(
                    hashMapOf(
                        "id" to o.optString("id"),
                        "amountMinor" to o.getInt("amountMinor"),
                        "what" to o.optString("what", "Other")
                    )
                )
            }
        } catch (_: Exception) {
        }
        file.delete()
        return out
    }

    private fun appendInbox(context: Context, id: String, amountMinor: Int, what: String) {
        val file = File(context.filesDir, INBOX)
        val arr = if (file.exists()) {
            try {
                JSONArray(file.readText())
            } catch (_: Exception) {
                JSONArray()
            }
        } else {
            JSONArray()
        }
        arr.put(
            JSONObject()
                .put("id", id)
                .put("amountMinor", amountMinor)
                .put("what", what)
        )
        file.writeText(arr.toString())
    }

    private fun bumpToday(context: Context, addMinor: Int) {
        val day = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val prefs = context.getSharedPreferences(QuickAddWidget.PREFS, Context.MODE_PRIVATE)
        val storedDay = prefs.getString("today_date", "")
        var total = if (storedDay == day) prefs.getInt("today_minor", 0) else 0
        total += addMinor
        val rupees = total / 100
        prefs.edit()
            .putInt("today_minor", total)
            .putString("today_date", day)
            .putString(QuickAddWidget.KEY_TODAY, "₹$rupees")
            .apply()
    }
}
