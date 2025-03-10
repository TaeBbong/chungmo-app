import 'package:flutter/material.dart';

class DeveloperInfoPage extends StatelessWidget {
  const DeveloperInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개발자 정보')),
      body: const Center(child: Text('개발자: 권태형\n이메일: mok05289@naver.com')),
    );
  }
}
