import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/budget/budget.dart';
import '../../core/db/account.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../shell/home_shell.dart';

const _tints = {
  AccountType.cash: Color(0xFFE5EFE0),
  AccountType.bank: Color(0xFFE4ECEF),
  AccountType.ewallet: Color(0xFFF6EDD4),
};

/// "Bank" tab: the user's accounts and e-wallets with their balances.
class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final txs = ref.watch(transactionsProvider(allTime));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, navBarClearance),
        children: [
          PageHeader(
            context: 'Rekening & dompet',
            title: 'Bank',
            actions: [
              IconButton.filledTonal(
                tooltip: 'Tambah rekening',
                onPressed: () => showAccountSheet(context),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          switch ((accounts, txs)) {
            (AsyncData(value: final a), AsyncData(value: final t)) => _Body(
              accounts: a,
              balances: [for (final x in a) x.balance(t)],
            ),
            (AsyncError(:final error), _) ||
            (_, AsyncError(:final error)) => ErrorText(error),
            _ => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.accounts, required this.balances});

  final List<Account> accounts;
  final List<double> balances;

  @override
  Widget build(BuildContext context) {
    final total = balances.fold(0.0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CozyCard(
          radius: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total saldo',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _signed(total),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: total < 0
                        ? AppColors.sunsetInk
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${accounts.length} rekening & dompet',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CozyCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final (i, a) in accounts.indexed) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.track,
                  ),
                _AccountRow(account: a, balance: balances[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Saldo = saldo awal + pemasukan − pengeluaran yang dicatat ke '
            'rekening itu. Ketuk rekening untuk mengubah atau menghapusnya.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

String _signed(double v) => '${v < 0 ? '−' : ''}${formatRupiah(v.abs())}';

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.balance});

  final Account account;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showAccountSheet(context, editing: account),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _tints[account.type],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                account.type.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    account.type.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _signed(balance),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: balance < 0
                    ? AppColors.sunsetInk
                    : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add an account, or change/delete [editing].
Future<void> showAccountSheet(BuildContext context, {Account? editing}) =>
    showCozySheet(
      context,
      title: editing == null ? 'Tambah rekening' : 'Ubah rekening',
      child: AccountForm(editing: editing),
    );

class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({super.key, this.editing});

  final Account? editing;

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  late final _name = TextEditingController(text: widget.editing?.name);
  late final _opening = TextEditingController(
    text: switch (widget.editing?.openingBalance) {
      final b? when b > 0 => formatThousands(b),
      _ => '',
    },
  );
  late var _type = widget.editing?.type ?? AccountType.bank;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await action();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final message = switch (e) {
        ArgumentError(name: 'name', message: 'sudah dipakai') =>
          'Nama itu sudah dipakai rekening lain',
        StateError(:final message) => message,
        _ => 'Gagal menyimpan: $e',
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _save() {
    final editing = widget.editing;
    final account = Account()
      ..name = _name.text
      ..type = _type
      ..openingBalance = parseRupiah(_opening.text) ?? 0;
    if (editing != null) account.id = editing.id;
    return _run(
      () => ref.read(repositoryProvider).saveAccount(account),
      editing == null ? 'Rekening ditambahkan' : 'Rekening disimpan',
    );
  }

  Future<void> _delete(Account account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${account.name}?'),
        content: const Text(
          'Catatan yang sudah ada tetap tersimpan, tapi tidak lagi dihitung '
          'ke saldo rekening mana pun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => ref.read(repositoryProvider).deleteAccount(account.id),
      '${account.name} dihapus',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canSave = _name.text.trim().isNotEmpty && !_busy;
    final editing = widget.editing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: editing == null,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama',
            hintText: 'mis. BCA, Jago, DANA',
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        Text('Jenis', style: text.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final t in AccountType.values)
              ChoiceChip(
                label: Text('${t.emoji} ${t.label}'),
                selected: t == _type,
                showCheckmark: false,
                onSelected: (_) => setState(() => _type = t),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _opening,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Saldo awal (opsional)',
            helperText: 'Saldo sebelum mulai mencatat di Koin',
            prefixText: 'Rp ',
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: Text(_busy ? 'Menyimpan…' : 'SIMPAN'),
        ),
        if (editing != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _busy ? null : () => _delete(editing),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Hapus rekening'),
            style: TextButton.styleFrom(foregroundColor: AppColors.sunsetInk),
          ),
        ],
      ],
    );
  }
}
