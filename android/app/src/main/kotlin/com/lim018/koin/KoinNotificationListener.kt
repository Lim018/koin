package com.lim018.koin

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.text.NumberFormat
import java.util.Locale
import java.util.concurrent.atomic.AtomicInteger

/**
 * Reads payment notifications from enabled sources (PRD 4.3) and asks
 * "Catat Rp25.000 sebagai Makan?" with [YA, CATAT] [UBAH] [ABAIKAN].
 * Notification text is only parsed in memory; nothing is stored or sent.
 */
class KoinNotificationListener : NotificationListenerService() {

    /** Recently handled "key:amount" → time, so re-posted updates don't ask twice. */
    private val recent = LinkedHashMap<String, Long>()

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (sbn.packageName == packageName || sbn.isOngoing) return
        val n = sbn.notification
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val debuggable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        val source = TransactionParser.sourceOf(sbn.packageName, debuggable) ?: return
        val prefs = KoinPrefs.get(this)
        if (!KoinPrefs.sourceEnabled(prefs, source)) return

        val extras = n.extras
        val text = listOfNotNull(
            extras.getCharSequence(Notification.EXTRA_TITLE),
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_TEXT),
        ).joinToString(" · ")
        val tx = TransactionParser.parse(sbn.packageName, text, debuggable) ?: return
        if (!markHandled("${sbn.key}:${tx.amount}", sbn.postTime)) return

        val detected = detectedUri(tx, sbn.postTime)
        if (prefs.getBoolean(KoinPrefs.CONFIRM, true)) {
            askToLog(this, tx, detected)
        } else {
            NotificationActionReceiver.logInBackground(this, detected)
        }
    }

    private fun markHandled(id: String, now: Long): Boolean = synchronized(recent) {
        recent.entries.removeAll { now - it.value > DEDUPE_WINDOW_MS }
        if (recent.containsKey(id)) return false
        recent[id] = now
        true
    }

    companion object {
        private const val CHANNEL_ID = "koin_auto"
        private const val DEDUPE_WINDOW_MS = 10 * 60 * 1000L
        // Seeded from the clock (bounded so id * 4 + 3 never overflows).
        private val nextId = AtomicInteger(((System.currentTimeMillis() / 1000) % 100_000_000).toInt())

        /** Shared with Dart (DetectedPayment.fromUri). */
        fun detectedUri(tx: DetectedTransaction, timestamp: Long): Uri =
            Uri.Builder().scheme("koin").authority("payment")
                .appendQueryParameter("amount", tx.amount.toString())
                .appendQueryParameter("category", tx.category)
                .appendQueryParameter("wallet", tx.wallet)
                .appendQueryParameter("ts", timestamp.toString())
                .build()

        private fun askToLog(context: Context, tx: DetectedTransaction, detected: Uri) {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID, "Catat otomatis", NotificationManager.IMPORTANCE_DEFAULT,
                    ).apply { description = "Konfirmasi transaksi dari notifikasi bank & e-wallet" },
                )
            }

            val id = nextId.incrementAndGet()
            val rupiah = "Rp" + NumberFormat.getIntegerInstance(Locale("id", "ID")).format(tx.amount)

            fun action(kind: String, slot: Int) = PendingIntent.getBroadcast(
                context,
                id * 4 + slot, // unique per notification and action
                Intent(context, NotificationActionReceiver::class.java)
                    .setAction(kind)
                    .setData(detected)
                    .putExtra(NotificationActionReceiver.EXTRA_NOTIFICATION_ID, id),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val edit = PendingIntent.getActivity(
                context,
                id * 4 + 3,
                QuickAddActivity.prefillIntent(context, detected, id),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            @Suppress("DEPRECATION")
            val builder =
                if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL_ID)
                else Notification.Builder(context)
            val notification = builder
                .setSmallIcon(R.drawable.ic_stat_koin)
                .setColor(context.getColor(R.color.sage))
                .setContentTitle("Koko menemukan transaksi ${tx.wallet}")
                .setContentText("Catat $rupiah sebagai ${tx.category}?")
                .setContentIntent(edit)
                .setAutoCancel(true)
                .addAction(Notification.Action.Builder(null, "YA, CATAT", action(NotificationActionReceiver.ACTION_LOG, 1)).build())
                .addAction(Notification.Action.Builder(null, "UBAH", edit).build())
                .addAction(Notification.Action.Builder(null, "ABAIKAN", action(NotificationActionReceiver.ACTION_DISMISS, 2)).build())
                .build()
            manager.notify(id, notification)
        }
    }
}
