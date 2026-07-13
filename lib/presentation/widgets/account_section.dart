import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/account.dart';
import '../theme/palette.dart';

/// 💌 마음 전하실 곳
///
/// Shows the parsed 축의금 accounts grouped by side.
/// Tapping a row copies its account number to the clipboard.
///
/// Renders nothing when no account was parsed from the invitation.
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

    // 사진(200)·장소(250) 등 다른 항목과 폭을 맞춘다.
    return SizedBox(
      width: 250,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text(
            '💌 마음 전하실 곳',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          children: [
            if (groomAccounts.isNotEmpty)
              _AccountGroup(title: '신랑측', accounts: groomAccounts),
            if (brideAccounts.isNotEmpty)
              _AccountGroup(title: '신부측', accounts: brideAccounts),
          ],
        ),
      ),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Palette.burgundy),
          ),
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

  /// `아버지 · 김철수`, falling back to whichever part exists.
  String get _label => [account.relation, account.holder]
      .where((part) => part.isNotEmpty)
      .join(' · ');

  /// `국민 123-45-6789`
  String get _number =>
      [account.bank, account.number].where((part) => part.isNotEmpty).join(' ');

  void _copy(BuildContext context) {
    if (account.number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: account.number));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('계좌번호를 복사했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      title: Text(
        _label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        _number,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.copy, size: 16),
      onTap: () => _copy(context),
    );
  }
}
