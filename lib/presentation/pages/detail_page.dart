import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/schedule.dart';
import '../../core/utils/date_converter.dart';
import '../controllers/detail_viewmodel.dart';

class DetailPage extends StatefulWidget {
  DetailPage({super.key});
  final Schedule schedule = Get.arguments as Schedule;

  @override
  // ignore: library_private_types_in_public_api
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool editMode = false;

  final DetailController controller = Get.put(DetailController());
  final TextEditingController groomController = TextEditingController();
  final TextEditingController brideController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  // final TextEditingController payController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    controller.schedule.value = widget.schedule;
    groomController.text = widget.schedule.groom;
    brideController.text = widget.schedule.bride;
    locationController.text = widget.schedule.location;
    linkController.text = widget.schedule.link;
    // payController.text = widget.schedule.pay;
    selectedDate = DateTime.parse(widget.schedule.date);
  }

  @override
  void dispose() {
    groomController.dispose();
    brideController.dispose();
    locationController.dispose();
    linkController.dispose();
    // payController.dispose();
    super.dispose();
  }

  void toggleEditMode() {
    setState(() {
      editMode = !editMode;
    });
  }

  void saveChanges() {
    setState(() {
      final Schedule editedSchedule = Schedule(
          link: controller.schedule.value!.link,
          thumbnail: controller.schedule.value!.thumbnail,
          groom: groomController.text,
          bride: brideController.text,
          date: selectedDate!.toIso8601String(),
          location: locationController.text);
      controller.editSchedule(editedSchedule);
      editMode = false;
      Get.snackbar('성공', '일정이 변경되었습니다.');
    });
  }

  InputDecoration customInputDecoration({required String labelText}) {
    return InputDecoration(
      filled: true,
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("삭제 확인"),
          ],
        ),
        content: const Text(
          "일정을 삭제하시겠습니까?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              controller.deleteSchedule(controller.schedule.value!.link);
              Get.snackbar('성공', '일정이 삭제되었습니다.');
              Get.offNamedUntil(
                  '/calendar', (route) => route.settings.name == '/');
            },
            child: const Text("삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.back(result: controller.schedule.value);
        // Get.offNamedUntil('/calendar', (route) => route.settings.name == '/');
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(editMode ? Icons.save : Icons.edit),
              onPressed: editMode ? saveChanges : toggleEditMode,
            ),
            editMode
                ? Container()
                : IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _showDeleteDialog();
                    },
                  ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 📸 사진 (수정 불가능)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                        controller.schedule.value!.thumbnail),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 👰‍♀️ & 🤵‍♂️ 신랑 & 신부 (수정 가능)
              editMode
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextField(
                              controller: groomController,
                              decoration:
                                  customInputDecoration(labelText: '신랑'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextField(
                              controller: brideController,
                              decoration:
                                  customInputDecoration(labelText: '신부'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '🤵‍♂️ ${controller.schedule.value!.groom} & 👰‍♀️ ${controller.schedule.value!.bride}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

              const SizedBox(height: 16),

              editMode
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        readOnly: true,
                        onTap: () => _selectDateTime(context),
                        controller: TextEditingController(
                          text: DateConverter.generateKrDate(
                              selectedDate!.toIso8601String()),
                        ), // 날짜를 TextField에 표시
                        decoration: customInputDecoration(
                          labelText: '날짜',
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : Text(
                      '📅 ${DateConverter.generateKrDate(controller.schedule.value!.date)}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),

              const SizedBox(height: 16),

              // 🏡 장소 (수정 가능)
              editMode
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Flexible(
                            child: TextField(
                              controller: locationController,
                              decoration:
                                  customInputDecoration(labelText: '장소'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: 250,
                      child: Text(
                        '🏡 ${controller.schedule.value!.location}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

              const SizedBox(height: 12),

              // 🔗 링크 열기 / 수정 불가
              editMode
                  ? Container()
                  : GestureDetector(
                      onTap: () async {
                        final Uri url =
                            Uri.parse(controller.schedule.value!.link);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '🔗 링크 열기',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

              const SizedBox(height: 8),

              // 💰 축의금 (수정 가능)
              // editMode
              //     ? SizedBox(
              //         width: 150,
              //         child: TextField(
              //           // controller: payController,
              //           keyboardType: TextInputType.number,
              //           decoration: const InputDecoration(labelText: '축의금'),
              //         ),
              //       )
              //     : Text(
              //         // '💰 축의금 ${controller.schedule.value!.pay}만원',
              //         '💰 축의금 10만원',
              //         style: const TextStyle(
              //             fontSize: 16, fontWeight: FontWeight.bold),
              //       ),
            ],
          ),
        ),
      ),
    );
  }
}
