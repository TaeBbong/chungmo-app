import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/di/di.dart';
import '../../domain/entities/account.dart';
import '../theme/motions.dart';
import 'info_row.dart';

/// The '계좌' row of the detail card.
///
/// Expands into the groom's and the bride's accounts; tapping one copies its
/// account number. Renders nothing when the invitation had no account at all.
///
/// Distinct from the '축의금' row, which is what the user gave.
class AccountSection extends StatelessWidget {
  final List<Account> groomAccounts;
  final List<Account> brideAccounts;

  const AccountSection({
    super.key,
    required this.groomAccounts,
    required this.brideAccounts,
  });

  @override
  Widget build(BuildContext context) {
    if (groomAccounts.isEmpty && brideAccounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return InfoRow.expandable(
      icon: Icons.card_giftcard,
      label: '계좌',
      value: '마음 전하실 곳',
      children: [
        if (groomAccounts.isNotEmpty)
          _AccountGroup(title: '신랑측', side: 'groom', accounts: groomAccounts),
        if (brideAccounts.isNotEmpty)
          _AccountGroup(title: '신부측', side: 'bride', accounts: brideAccounts),
      ],
    );
  }
}

class _AccountGroup extends StatelessWidget {
  final String title;
  final String side;
  final List<Account> accounts;

  const _AccountGroup({
    required this.title,
    required this.side,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: InfoRowMetrics.labelStyle
              .copyWith(color: InfoRowMetrics.mutedColor(context)),
        ),
        ...accounts
            .map((account) => _AccountTile(account: account, side: side)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AccountTile extends StatefulWidget {
  final Account account;
  final String side;

  const _AccountTile({required this.account, required this.side});

  @override
  State<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<_AccountTile> {
  Account get account => widget.account;

  /// While set the trailing icon shows a confirming check instead of copy.
  bool _copied = false;
  Timer? _copiedReset;

  /// `국민 123-45-6789`
  String get _number =>
      [account.bank, account.number].where((part) => part.isNotEmpty).join(' ');

  /// `아버지 · 김철수`, falling back to whichever part exists.
  String get _holder => [account.relation, account.holder]
      .where((part) => part.isNotEmpty)
      .join(' · ');

  void _copy(BuildContext context) {
    if (account.number.isEmpty) return;
    getIt<AnalyticsService>().logEvent(AnalyticsEvents.accountCopied,
        parameters: {AnalyticsParams.side: widget.side});
    Clipboard.setData(ClipboardData(text: account.number));
    // Physical confirmation on top of the visual ones; copying is the one
    // action here the user performs mid-motion, on their way to a bank app.
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    _copiedReset?.cancel();
    _copiedReset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('계좌번호를 복사했습니다.')),
    );
  }

  @override
  void didUpdateWidget(_AccountTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tiles are matched by position, so this State can be reused for a
    // different account; the check icon and its reset timer must not
    // carry over to it.
    if (oldWidget.account != widget.account) {
      _copiedReset?.cancel();
      _copied = false;
    }
  }

  @override
  void dispose() {
    _copiedReset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _copy(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_number, style: InfoRowMetrics.valueStyle),
                  if (_holder.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _holder,
                        style: InfoRowMetrics.hintStyle.copyWith(
                            color: InfoRowMetrics.faintColor(context)),
                      ),
                    ),
                ],
              ),
            ),
            // Copy icon morphs into a check for a moment after copying.
            AnimatedSwitcher(
              duration: Motions.quick,
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _copied
                  ? const Icon(Icons.check_rounded,
                      key: ValueKey<String>('copied'),
                      size: 16,
                      color: Colors.green)
                  : Icon(Icons.copy,
                      key: const ValueKey<String>('copy'),
                      size: 16,
                      color: InfoRowMetrics.faintColor(context)),
            ),
          ],
        ),
      ),
    );
  }
}
