import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/create_viewmodel.dart';

class CreatePage extends StatelessWidget {
  final CreateController controller = Get.put(CreateController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(onSubmitted: controller.analyzeLink),
          Obx(() => controller.isLoading.value ? CircularProgressIndicator() : Text(controller.schedule.value?.link ?? '')),
        ],
      ),
    );
  }
}
