import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/utils/constants.dart';
import '../theme/dimens.dart';
import '../theme/palette.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('앱 정보')),
        body: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final String version = snapshot.hasData
                ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                : '...';

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: Dimens.md),
              children: [
                _AppHero(version: version),
                const SizedBox(height: Dimens.lg),
                _SectionCard(
                  children: [
                    _MenuRow(
                      icon: Icons.rocket_launch_outlined,
                      title: '앱 업데이트',
                      trailing: Text('최신 버전',
                          style: Theme.of(context).textTheme.bodyMedium),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('이미 최신 버전을 사용하고 있어요.')));
                      },
                    ),
                    _MenuRow(
                      icon: Icons.auto_awesome_outlined,
                      title: '앱 소개 다시 보기',
                      onTap: () => navigatorKey.currentState
                          ?.pushNamed('/onboarding', arguments: true),
                    ),
                    _MenuRow(
                      icon: Icons.tour_outlined,
                      title: '튜토리얼 다시 보기',
                      // Home owns the coach mark targets, so pop back with a
                      // result asking it to replay the tour.
                      onTap: () => navigatorKey.currentState?.pop(true),
                    ),
                    _MenuRow(
                      icon: Icons.person_outline,
                      title: '개발자 정보',
                      onTap: () => navigatorKey.currentState
                          ?.pushNamed('/about/developer_info'),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.md),
                _SectionCard(
                  children: [
                    _MenuRow(
                      icon: Icons.description_outlined,
                      title: '이용 약관',
                      onTap: () => _openUrl(Constants.termsUrl),
                    ),
                    _MenuRow(
                      icon: Icons.lock_outline,
                      title: '개인정보 처리방침',
                      onTap: () => _openUrl(Constants.privacyUrl),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// App icon, name and version — the page's identity header.
class _AppHero extends StatelessWidget {
  final String version;

  const _AppHero({required this.version});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: Dimens.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimens.radiusXl),
          child: Image.asset(
            'assets/images/icon_trans_960.png',
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: Dimens.md),
        Text('청모', style: textTheme.headlineSmall),
        const SizedBox(height: Dimens.xs),
        Text('버전 $version', style: textTheme.bodyMedium),
      ],
    );
  }
}

/// Rounded card grouping related menu rows, Toss-settings style.
class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Dimens.screenPadding),
      child: Material(
        color: Theme.of(context).brightness == Brightness.light
            ? Palette.surfaceMuted
            : Palette.grey850,
        borderRadius: BorderRadius.circular(Dimens.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

/// A single tappable settings row: icon, title, optional trailing.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Dimens.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: Dimens.md),
            Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            trailing ??
                Icon(Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class DeveloperInfoPage extends StatelessWidget {
  const DeveloperInfoPage({super.key});

  static const String _email = 'mok05289@naver.com';
  static const String _githubUrl = 'https://github.com/TaeBbong';

  /// `canLaunchUrl` is skipped on purpose: it reports false for schemes
  /// missing from the platform query allowlists (e.g. mailto on Android),
  /// even when an app could handle them. Launch directly and surface the
  /// failure instead.
  Future<void> _launch(BuildContext context, Uri uri) async {
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결할 앱을 찾지 못했어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('개발자 정보')),
      // Scrolls when the viewport is short (landscape, large system text),
      // while the copyright stays pinned to the bottom otherwise.
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: Dimens.lg),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      '태',
                      style: textTheme.headlineSmall
                          ?.copyWith(color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(height: Dimens.md),
                  Text('권태형', style: textTheme.headlineSmall),
                  const SizedBox(height: Dimens.xs),
                  Text('청모를 만들고 있는 개발자예요.', style: textTheme.bodyMedium),
                  const SizedBox(height: Dimens.lg),
                  _SectionCard(
                    children: [
                      _MenuRow(
                        icon: Icons.mail_outline,
                        title: '이메일 보내기',
                        trailing: Text(_email, style: textTheme.bodyMedium),
                        onTap: () => _launch(
                            context, Uri(scheme: 'mailto', path: _email)),
                      ),
                      _MenuRow(
                        icon: Icons.code,
                        title: 'GitHub',
                        onTap: () => _launch(context, Uri.parse(_githubUrl)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: Dimens.lg, bottom: Dimens.lg),
                    child: Text(
                      'Copyright 2025. TaeBbong All rights reserved.',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
