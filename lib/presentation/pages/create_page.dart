/// Step 8:
/// Pages(widget)
///
/// Presentation layer connected with controller

import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/di.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/constants.dart';
import '../controllers/create_viewmodel.dart';
import '../theme/palette.dart';
import '../widgets/schedule_detail_column.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final CreateController controller = Get.put(CreateController());
  final TextEditingController _textEditingController = TextEditingController();
  final NotificationService notificationService = getIt<NotificationService>();

  @override
  void initState() {
    super.initState();
  }

  void _onSubmit() {
    String userInput = _textEditingController.text.trim();
    if (userInput.isNotEmpty) {
      controller.analyzeLink(userInput);
      _textEditingController.clear();
    }
  }

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
              // TODO: Remove test button
              notificationService.checkScheduledNotifications();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'terms':
                  final Uri url = Uri.parse(Constants.termsUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  break;
                case 'privacy':
                  final Uri url = Uri.parse(Constants.privacyUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  break;
                case 'about':
                  Get.toNamed('/about');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'terms',
                child: Text('이용 약관'),
              ),
              const PopupMenuItem(
                value: 'privacy',
                child: Text('개인정보 처리방침'),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Text('앱 정보'),
              ),
            ],
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
              return controller.isError.value
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '다시 시도해주세요.',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '잠시 서버에 문제가 생겼어요.',
                          style: TextStyle(fontSize: 14),
                        )
                      ],
                    )
                  : controller.schedule.value?.link != null
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
      bottomSheet: Obx(() {
        return controller.schedule.value?.link != null
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.resetState();
                      Get.snackbar('성공', '일정을 캘린더에 저장했습니다.');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.burgundy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "확인",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    controller: _textEditingController,
                    onSubmitted: (value) => _onSubmit(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '링크 입력...',
                      hintStyle:
                          TextStyle(fontSize: 14, color: Palette.grey500),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, size: 20),
                        onPressed: _onSubmit,
                      ),
                    ),
                  ),
                ),
              );
      }),
    );
  }
}
