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
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

/**
 * 4x4 home screen widget: today's spending, Koko's mood and "+ TAMBAH".
 * Data is written by the Flutter side (lib/core/home_widget_sync.dart).
 */
class KokoWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val summary = Summary.read(widgetData)
        val showKoko = widgetData.getBoolean(KoinPrefs.SHOW_KOKO, true)
        val moodFollows = widgetData.getBoolean(KoinPrefs.MOOD_FOLLOWS, true)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, render(context, summary, showKoko, moodFollows))
        }
    }

    private fun render(
        context: Context,
        s: Summary,
        showKoko: Boolean,
        moodFollows: Boolean,
    ): RemoteViews {
        val mood = if (moodFollows) s.mood else "happy"
        val rupiah = NumberFormat.getIntegerInstance(Locale("id", "ID"))
        val over = s.spent > s.budget
        val percent = if (s.budget > 0) (s.spent * 100.0 / s.budget).roundToInt() else 0

        return RemoteViews(context.packageName, R.layout.koko_widget).apply {
            setTextViewText(R.id.amount, rupiah.format(s.spent))

            setTextViewText(
                R.id.status_pill,
                if (over) "Lewat Rp ${rupiah.format(s.spent - s.budget)}"
                else "Sisa Rp ${rupiah.format(s.budget - s.spent)}",
            )
            setInt(
                R.id.status_pill, "setBackgroundResource",
                if (over) R.drawable.widget_pill_over else R.drawable.widget_pill_under,
            )
            setTextColor(R.id.status_pill, context.getColor(if (over) R.color.sunset_ink else R.color.sage_dark))

            setViewVisibility(R.id.mood_tile, if (showKoko) View.VISIBLE else View.GONE)
            val (sprite, label) = when (mood) {
                "grumpy" -> R.drawable.koko_grumpy to "Koko kesal"
                "neutral" -> R.drawable.koko_neutral to "Koko khawatir"
                else -> R.drawable.koko_happy to "Koko senang"
            }
            setImageViewResource(R.id.koko, sprite)
            setContentDescription(R.id.koko, label)
            setTextViewText(R.id.mood_label, label)
            setTextColor(
                R.id.mood_label,
                context.getColor(if (mood == "happy") R.color.sage_dark else R.color.sunset_ink),
            )

            setTextViewText(R.id.target_label, "Target harian Rp ${rupiah.format(s.budget)}")
            setTextViewText(R.id.percent, "$percent%")
            setTextColor(R.id.percent, context.getColor(if (over) R.color.sunset_ink else R.color.sage_dark))
            setViewVisibility(R.id.progress_under, if (over) View.GONE else View.VISIBLE)
            setViewVisibility(R.id.progress_over, if (over) View.VISIBLE else View.GONE)
            setProgressBar(R.id.progress_under, 100, percent.coerceIn(0, 100), false)

            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            setOnClickPendingIntent(
                R.id.btn_add,
                HomeWidgetLaunchIntent.getActivity(context, QuickAddActivity::class.java),
            )
        }
    }

    /** Mirrors WidgetKeys in lib/core/home_widget_sync.dart. */
    private data class Summary(val spent: Long, val budget: Long, val mood: String) {
        companion object {
            private const val DEFAULT_BUDGET = 200_000L

            fun read(prefs: SharedPreferences): Summary {
                val budget = (prefs.all["koin_budget"] as? Number)?.toLong() ?: DEFAULT_BUDGET
                val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                // Totals from a previous day are stale: a new day starts at zero.
                if (prefs.getString("koin_date", null) != today) {
                    return Summary(0, budget, "happy")
                }
                return Summary(
                    spent = (prefs.all["koin_spent"] as? Number)?.toLong() ?: 0,
                    budget = budget,
                    mood = prefs.getString("koin_mood", null) ?: "happy",
                )
            }
        }
    }
}
