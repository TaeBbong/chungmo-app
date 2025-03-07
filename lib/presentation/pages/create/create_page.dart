/// Step 8:
/// Pages(widget)
///
/// Presentation layer connected with controller

import 'package:chungmo/presentation/widgets/schedule_detail_column.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../controllers/create_viewmodel.dart';
import '../../theme/palette.dart';

class CreatePage extends StatelessWidget {
  final CreateController controller = Get.put(CreateController());
  CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () {
            Get.toNamed('/calendar');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: 알림 관련 동작 추가(다가올 일정 local push notification)
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 더보기 버튼 동작 추가(about, license, privacy)
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: 10,
            left: 30,
            child: Text('홈',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: DotLottieLoader.fromAsset(
                          'assets/images/analyze.lottie', frameBuilder:
                              (BuildContext ctx, DotLottie? dotlottie) {
                        if (dotlottie != null) {
                          return Lottie.memory(
                              dotlottie.animations.values.single);
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text('링크 분석 중...', style: TextStyle(fontSize: 16)),
                  ],
                );
              }
              return controller.schedule.value?.link != null
                  ? ScheduleDetailColumn(
                      schedule: controller.schedule.value!,
                      extraChildren: [
                        const SizedBox(height: 12),
                        Text(
                          '분석 결과를 일정에 추가할게요.',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Palette.burgundy),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '모바일 청첩장을 첨부해주세요.',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'AI가 자동으로 일정을 분석해드릴게요.',
                          style: TextStyle(fontSize: 14),
                        )
                      ],
                    );
            }),
          ),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(red: 0, blue: 0, green: 0, alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            onSubmitted: controller.analyzeLink,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '링크 입력...',
              hintStyle: TextStyle(fontSize: 14, color: Palette.grey500),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, size: 20),
                onPressed: () {
                  controller.analyzeLink;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
