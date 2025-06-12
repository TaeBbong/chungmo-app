import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/navigation/app_navigation.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('앱 정보')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData
              ? '버전 ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
              : '버전 정보 불러오는 중...';

          return ListView(
            children: [
              ListTile(
                title: const Text('앱 버전'),
                subtitle: Text(version),
              ),
              const Divider(),
              ListTile(
                title: const Text('앱 업데이트'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('최신 버전입니다.')));
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('개발자 정보'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => navigatorKey.currentState
                    ?.pushNamed('/about/developer_info'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DeveloperInfoPage extends StatelessWidget {
  const DeveloperInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개발자 정보')),
      body: const Center(
          child: Text(
              '개발자: 권태형\n이메일: mok05289@naver.com\nCopyright 2025. TaeBbong All rights reserved.')),
    );
  }
}
