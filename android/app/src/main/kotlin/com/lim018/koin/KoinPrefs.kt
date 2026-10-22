package com.lim018.koin

import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Settings shared with Dart through home_widget's storage; keys and defaults
 * mirror lib/core/native_settings.dart.
 */
object KoinPrefs {
    const val CONFIRM = "koin_confirm"
    const val SHOW_KOKO = "koin_show_koko"
    const val MOOD_FOLLOWS = "koin_mood_follows"

    fun get(context: Context): SharedPreferences = HomeWidgetPlugin.getData(context)

    fun sourceEnabled(prefs: SharedPreferences, source: TransactionParser.Source): Boolean =
        prefs.getBoolean(source.prefKey, source != TransactionParser.Source.EWALLET)
}
