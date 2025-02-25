/// Step 8:
/// Pages(widget)
/// 
/// Presentation layer connected with controller


import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/create_viewmodel.dart';

class CreatePage extends StatelessWidget {
  final CreateController controller = Get.put(CreateController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () {
            Get.toNamed('/calendar'); // CalendarPage로 이동
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // 알림 관련 동작 추가
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // 더보기 버튼 동작 추가
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('링크 분석 중...', style: TextStyle(fontSize: 16)),
                ],
              );
            }
            return Text(
              controller.schedule.value?.link ?? '링크를 입력하세요.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            );
          }),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onSubmitted: controller.analyzeLink,
          decoration: InputDecoration(
            hintText: '링크 입력...',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                // 입력한 텍스트를 분석
                controller.analyzeLink;
              },
            ),
          ),
        ),
      ),
    );
  }
}
