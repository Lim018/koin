package com.lim018.koin

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

/**
 * Transparent pop-up launched by the home widget's "+ TAMBAH" button, or by
 * [UBAH] on an auto-read notification (then pre-filled). Runs the
 * `quickAddMain` Dart entry point instead of the full app, and finishes
 * itself once the expense is saved (SystemNavigator.pop).
 */
class QuickAddActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String = "quickAddMain"

    override fun getDartEntrypointArgs(): List<String> =
        listOfNotNull(intent.getStringExtra(EXTRA_PREFILL))

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        cancelSourceNotification()
    }

    /** singleTask: a new launch while open restarts with the new pre-fill. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        cancelSourceNotification()
        recreate()
    }

    private fun cancelSourceNotification() {
        val id = intent.getIntExtra(NotificationActionReceiver.EXTRA_NOTIFICATION_ID, -1)
        if (id != -1) getSystemService(NotificationManager::class.java).cancel(id)
    }

    companion object {
        private const val EXTRA_PREFILL = "prefill"

        fun prefillIntent(context: Context, detected: Uri, notificationId: Int): Intent =
            Intent(context, QuickAddActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                .putExtra(EXTRA_PREFILL, detected.toString())
                .putExtra(NotificationActionReceiver.EXTRA_NOTIFICATION_ID, notificationId)
    }
}
