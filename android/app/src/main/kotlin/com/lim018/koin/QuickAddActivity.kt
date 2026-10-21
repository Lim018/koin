package com.lim018.koin

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

/**
 * Transparent pop-up launched by the home widget's "+ TAMBAH" button.
 * Runs the `quickAddMain` Dart entry point instead of the full app, and
 * finishes itself once the expense is saved (SystemNavigator.pop).
 */
class QuickAddActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String = "quickAddMain"

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent
}
