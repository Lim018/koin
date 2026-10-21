package com.lim018.koin

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver

/** Handles [YA, CATAT] and [ABAIKAN] on the auto-read notification. */
class NotificationActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
        if (id != -1) context.getSystemService(NotificationManager::class.java).cancel(id)
        val detected = intent.data
        if (intent.action == ACTION_LOG && detected != null) logInBackground(context, detected)
    }

    companion object {
        const val ACTION_LOG = "com.lim018.koin.LOG"
        const val ACTION_DISMISS = "com.lim018.koin.DISMISS"
        const val EXTRA_NOTIFICATION_ID = "notification_id"

        /**
         * Runs the Dart `autoLogCallback` (registered via
         * HomeWidget.registerInteractivityCallback) in a background isolate,
         * which writes the transaction to Isar and refreshes the widget.
         */
        fun logInBackground(context: Context, detected: Uri) {
            HomeWidgetBackgroundReceiver().onReceive(context, Intent().setData(detected))
        }
    }
}
