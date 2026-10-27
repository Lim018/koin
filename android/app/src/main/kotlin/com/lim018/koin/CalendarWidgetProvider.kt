package com.lim018.koin

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * 4x4 home screen widget: this month's calendar with each day tinted green
 * (within the daily target) or orange (over it), like the in-app calendar.
 * Data is written by the Flutter side (lib/core/home_widget_sync.dart).
 */
class CalendarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, render(context, widgetData))
        }
    }

    private fun render(context: Context, prefs: SharedPreferences): RemoteViews {
        val id = Locale("id", "ID")
        val now = Calendar.getInstance()
        val todayDay = now.get(Calendar.DAY_OF_MONTH)
        val daysInMonth = now.getActualMaximum(Calendar.DAY_OF_MONTH)
        val totals = monthTotals(prefs, now)
        val budget = (prefs.all["koin_budget"] as? Number)?.toLong() ?: DEFAULT_BUDGET

        // Monday-first: Calendar.MONDAY (2) → 0 … Calendar.SUNDAY (1) → 6.
        val first = (now.clone() as Calendar).apply { set(Calendar.DAY_OF_MONTH, 1) }
        val lead = (first.get(Calendar.DAY_OF_WEEK) + 5) % 7
        val weeks = (lead + daysInMonth + 6) / 7

        return RemoteViews(context.packageName, R.layout.calendar_widget).apply {
            setTextViewText(R.id.cal_month, SimpleDateFormat("MMMM yyyy", id).format(now.time))
            val spent = totals.filterNotNull().sum()
            setTextViewText(R.id.cal_total, "Rp ${NumberFormat.getIntegerInstance(id).format(spent)}")

            val under = totals.count { it != null && it <= budget }
            val over = totals.count { it != null && it > budget }
            setTextViewText(R.id.cal_under, "Di bawah target · $under")
            setTextViewText(R.id.cal_over, "Lewat target · $over")

            for ((w, rowId) in WEEK_ROWS.withIndex()) {
                removeAllViews(rowId)
                setViewVisibility(rowId, if (w < weeks) View.VISIBLE else View.GONE)
                if (w >= weeks) continue
                for (col in 0 until 7) {
                    val day = w * 7 + col - lead + 1
                    addView(rowId, cell(context, day, daysInMonth, todayDay, totals, budget))
                }
            }

            setOnClickPendingIntent(
                R.id.calendar_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
        }
    }

    private fun cell(
        context: Context,
        day: Int,
        daysInMonth: Int,
        today: Int,
        totals: List<Long?>,
        budget: Long,
    ): RemoteViews = RemoteViews(context.packageName, R.layout.calendar_cell).apply {
        if (day < 1 || day > daysInMonth) {
            setTextViewText(R.id.day, "")
            return@apply
        }
        setTextViewText(R.id.day, day.toString())
        val total = totals.getOrNull(day - 1)
        val isToday = day == today
        val (background, ink) = when {
            total == null -> (if (isToday) R.drawable.cal_day_today else 0) to
                (if (day > today) R.color.text_secondary else R.color.text_primary)
            total > budget -> (if (isToday) R.drawable.cal_day_over_today else R.drawable.cal_day_over) to
                R.color.sunset_ink
            else -> (if (isToday) R.drawable.cal_day_under_today else R.drawable.cal_day_under) to
                R.color.sage_dark
        }
        if (background != 0) setInt(R.id.day, "setBackgroundResource", background)
        setTextColor(R.id.day, context.getColor(ink))
    }

    /**
     * Spending per day of [now]'s month (null = no entries). A stored month
     * other than the current one is stale, so the new month starts empty.
     */
    private fun monthTotals(prefs: SharedPreferences, now: Calendar): List<Long?> {
        val days = now.getActualMaximum(Calendar.DAY_OF_MONTH)
        val month = SimpleDateFormat("yyyy-MM", Locale.US).format(now.time)
        if (prefs.getString("koin_cal_month", null) != month) return List(days) { null }
        val parts = prefs.getString("koin_cal_totals", null)?.split(',') ?: emptyList()
        return List(days) { parts.getOrNull(it)?.toLongOrNull() }
    }

    private companion object {
        const val DEFAULT_BUDGET = 200_000L
        val WEEK_ROWS = intArrayOf(
            R.id.week0, R.id.week1, R.id.week2, R.id.week3, R.id.week4, R.id.week5,
        )
    }
}
