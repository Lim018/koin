import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/native_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';

const _widgetProvider = 'com.lim018.koin.KokoWidgetProvider';

/// "Otomatisasi": notification auto-read and widget appearance.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  Map<NativeSetting, bool>? _values;
  bool? _listenerEnabled;
  bool? _canNotify;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Permissions are granted in system settings, so re-check on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadPermissions();
  }

  Future<void> _load() async {
    final values = {for (final s in NativeSetting.values) s: await s.read()};
    if (mounted) setState(() => _values = values);
    await _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    if (!AutomationPermissions.supported) return;
    final listener = await AutomationPermissions.listenerEnabled();
    final notify = await AutomationPermissions.canPostNotifications();
    if (mounted) {
      setState(() {
        _listenerEnabled = listener;
        _canNotify = notify;
      });
    }
  }

  Future<void> _set(NativeSetting setting, bool value) async {
    setState(() => _values = {..._values!, setting: value});
    await setting.write(value);
    if (setting == NativeSetting.showKoko ||
        setting == NativeSetting.moodFollows) {
      await HomeWidget.updateWidget(qualifiedAndroidName: _widgetProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = _values;
    // The cream gradient sits behind the whole Scaffold (app bar included).
    return CozyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Otomatisasi'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
        ),
        body: SizedBox.expand(
          child: values == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _AccessCard(
                      listenerEnabled: _listenerEnabled,
                      canNotify: _canNotify,
                    ),
                    const _SectionLabel('SUMBER NOTIFIKASI'),
                    _Group(
                      children: [
                        _toggle(
                          NativeSetting.gopay,
                          Icons.account_balance_wallet_outlined,
                          const Color(0xFFE5EFE0),
                          'Baca Notif GoPay',
                          'Gojek & GoPay',
                        ),
                        _toggle(
                          NativeSetting.bank,
                          Icons.account_balance_outlined,
                          const Color(0xFFF6EDD4),
                          'Baca Notif M-Banking',
                          'BCA, Livin’ Mandiri, BRImo, BNI',
                        ),
                        _toggle(
                          NativeSetting.ewallet,
                          Icons.phone_android_outlined,
                          const Color(0xFFF1ECE5),
                          'E-Wallet lainnya',
                          'OVO, DANA, ShopeePay',
                        ),
                        _toggle(
                          NativeSetting.confirm,
                          Icons.check_rounded,
                          const Color(0xFFFCE8DC),
                          'Tanya sebelum mencatat',
                          values[NativeSetting.confirm]!
                              ? 'Tampilkan YA, CATAT / UBAH / ABAIKAN'
                              : 'Langsung dicatat tanpa bertanya',
                        ),
                      ],
                    ),
                    const _SectionLabel('TAMPILAN WIDGET'),
                    _Group(
                      children: [
                        _toggle(
                          NativeSetting.showKoko,
                          null,
                          null,
                          'Tampilkan Koko',
                          'Maskot muncul di pojok widget',
                        ),
                        _toggle(
                          NativeSetting.moodFollows,
                          null,
                          null,
                          'Ekspresi ikut budget',
                          'Senang, khawatir, atau kesal',
                        ),
                      ],
                    ),
                    if (AutomationPermissions.supported) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => HomeWidget.requestPinWidget(
                          qualifiedAndroidName: _widgetProvider,
                        ),
                        icon: const Icon(Icons.widgets_outlined),
                        label: const Text('Pasang widget di beranda'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.sageDark,
                          side: const BorderSide(color: AppColors.chipBorder),
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Koin tidak pernah mengirim isi notifikasi ke server. '
                      'Kamu bisa mematikan akses kapan saja.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _toggle(
    NativeSetting setting,
    IconData? icon,
    Color? tint,
    String title,
    String subtitle,
  ) {
    return SwitchListTile(
      value: _values![setting]!,
      onChanged: (v) => _set(setting, v),
      activeTrackColor: AppColors.sage,
      contentPadding: EdgeInsets.zero,
      secondary: icon == null
          ? null
          : Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.textOnChip),
            ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.listenerEnabled, required this.canNotify});

  /// Null while unknown or on non-Android platforms.
  final bool? listenerEnabled;
  final bool? canNotify;

  @override
  Widget build(BuildContext context) {
    return CozyCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catat otomatis dari notifikasi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Koin membaca notifikasi transaksi, lalu Koko menanyakan '
            'kategorinya. Semua diproses di perangkatmu.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textOnChip,
            ),
          ),
          if (!AutomationPermissions.supported) ...[
            const SizedBox(height: 12),
            const StatusPill(label: 'Hanya tersedia di Android', over: true),
          ] else ...[
            const SizedBox(height: 12),
            _PermissionRow(
              granted: listenerEnabled,
              label: 'Akses notifikasi',
              action: 'Beri akses',
              onRequest: AutomationPermissions.openListenerSettings,
            ),
            const SizedBox(height: 8),
            _PermissionRow(
              granted: canNotify,
              label: 'Izin menampilkan pertanyaan',
              action: 'Izinkan',
              onRequest: AutomationPermissions.requestPostNotifications,
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.granted,
    required this.label,
    required this.action,
    required this.onRequest,
  });

  final bool? granted;
  final String label;
  final String action;
  final Future<void> Function() onRequest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          granted == true ? Icons.check_circle_rounded : Icons.error_outline,
          size: 18,
          color: granted == true ? AppColors.sage : AppColors.sunsetSoft,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        if (granted == false)
          TextButton(onPressed: onRequest, child: Text(action))
        else if (granted == true)
          const Text(
            'Aktif',
            style: TextStyle(fontSize: 12, color: AppColors.sageDark),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.textOnChip,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CozyCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.track),
            c,
          ],
        ],
      ),
    );
  }
}
