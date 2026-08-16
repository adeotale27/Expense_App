package com.spendping.spendping

import android.app.Activity
import android.os.Bundle
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.EditText

class WidgetComposeActivity : Activity() {
    private var category = "Food"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.compose_spend)

        val amount = findViewById<EditText>(R.id.amount)
        val other = findViewById<EditText>(R.id.other_name)
        val food = findViewById<Button>(R.id.cat_food)
        val fuel = findViewById<Button>(R.id.cat_fuel)
        val otherBtn = findViewById<Button>(R.id.cat_other)
        val save = findViewById<Button>(R.id.save)

        amount.requestFocus()
        amount.post {
            val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
            imm.showSoftInput(amount, InputMethodManager.SHOW_IMPLICIT)
        }

        fun select(name: String, showOther: Boolean) {
            category = name
            food.alpha = if (name == "Food") 1f else 0.45f
            fuel.alpha = if (name == "Fuel") 1f else 0.45f
            otherBtn.alpha = if (name == "Other") 1f else 0.45f
            other.visibility = if (showOther) View.VISIBLE else View.GONE
            if (showOther) {
                other.requestFocus()
                val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
                imm.showSoftInput(other, InputMethodManager.SHOW_IMPLICIT)
            }
        }

        select("Food", false)
        food.setOnClickListener { select("Food", false) }
        fuel.setOnClickListener { select("Fuel", false) }
        otherBtn.setOnClickListener { select("Other", true) }

        save.setOnClickListener {
            val major = amount.text.toString().trim().toDoubleOrNull() ?: 0.0
            if (major <= 0) {
                amount.error = "Enter an amount"
                amount.requestFocus()
                return@setOnClickListener
            }
            val minor = Math.round(major * 100).toInt()
            val what = if (category == "Other") {
                val typed = other.text.toString().trim()
                typed.ifEmpty { "Other" }
            } else {
                category
            }
            WidgetSpendWriter.save(this, minor, what)
            finish()
        }
    }
}
