import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/account.dart';
import '../theme/palette.dart';
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
          _AccountGroup(title: '신랑측', accounts: groomAccounts),
        if (brideAccounts.isNotEmpty)
          _AccountGroup(title: '신부측', accounts: brideAccounts),
      ],
    );
  }
}

class _AccountGroup extends StatelessWidget {
  final String title;
  final List<Account> accounts;

  const _AccountGroup({required this.title, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: InfoRowMetrics.labelStyle.copyWith(color: Palette.grey600),
        ),
        ...accounts.map((account) => _AccountTile(account: account)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;

  const _AccountTile({required this.account});

  /// `국민 123-45-6789`
  String get _number =>
      [account.bank, account.number].where((part) => part.isNotEmpty).join(' ');

  /// `아버지 · 김철수`, falling back to whichever part exists.
  String get _holder => [account.relation, account.holder]
      .where((part) => part.isNotEmpty)
      .join(' · ');

  void _copy(BuildContext context) {
    if (account.number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: account.number));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('계좌번호를 복사했습니다.')),
    );
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
                        style: InfoRowMetrics.hintStyle
                            .copyWith(color: Palette.grey500),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.copy, size: 16, color: Palette.grey500),
          ],
        ),
      ),
    );
  }
}
