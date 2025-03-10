import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
              // ListTile(
              //   title: const Text('오픈 소스 라이브러리'),
              //   trailing: const Icon(Icons.chevron_right),
              //   onTap: () => Get.toNamed('/open_source'),
              // ),
              ListTile(
                title: const Text('앱 업데이트'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.snackbar('알림', '최신 버전입니다.');
                },
              ),
              // const Divider(),
              // ListTile(
              //   title: const Text('개인정보처리방침'),
              //   trailing: const Icon(Icons.chevron_right),
              //   onTap: () => Get.toNamed('/privacy_policy'),
              // ),
              // ListTile(
              //   title: const Text('이용 약관'),
              //   trailing: const Icon(Icons.chevron_right),
              //   onTap: () => Get.toNamed('/terms_of_service'),
              // ),
              const Divider(),
              ListTile(
                title: const Text('개발자 정보'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed('/about/developer_info'),
              ),
            ],
          );
        },
      ),
    );
  }
}
