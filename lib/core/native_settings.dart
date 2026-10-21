import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// Boolean settings read by native code (notification listener, widget).
/// Keys and defaults mirror android/.../KoinPrefs.kt and TransactionParser.
enum NativeSetting {
  gopay('koin_src_gopay', true),
  bank('koin_src_bank', true),
  ewallet('koin_src_ewallet', false),
  confirm('koin_confirm', true),
  showKoko('koin_show_koko', true),
  moodFollows('koin_mood_follows', true);

  const NativeSetting(this.key, this.defaultValue);

  final String key;
  final bool defaultValue;

  Future<bool> read() async =>
      await HomeWidget.getWidgetData<bool>(key, defaultValue: defaultValue) ??
      defaultValue;

  Future<void> write(bool value) => HomeWidget.saveWidgetData<bool>(key, value);
}

/// Android permissions behind auto-read (MainActivity's method channel).
abstract final class AutomationPermissions {
  static const _channel = MethodChannel('com.lim018.koin/automation');

  static bool get supported => Platform.isAndroid;

  static Future<bool> listenerEnabled() async =>
      await _channel.invokeMethod<bool>('isListenerEnabled') ?? false;

  static Future<void> openListenerSettings() =>
      _channel.invokeMethod('openListenerSettings');

  static Future<bool> canPostNotifications() async =>
      await _channel.invokeMethod<bool>('canPostNotifications') ?? false;

  static Future<void> requestPostNotifications() =>
      _channel.invokeMethod('requestPostNotifications');
}
