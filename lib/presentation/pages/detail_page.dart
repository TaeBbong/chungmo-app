import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/schedule.dart';
import '../../core/utils/date_converter.dart';

// TODO: 날짜 포맷 통일 및 확인
class DetailPage extends StatefulWidget {
  DetailPage({super.key});
  final Schedule schedule = Get.arguments as Schedule;

  @override
  // ignore: library_private_types_in_public_api
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool editMode = false; // ✏️ 수정 모드 상태

  final TextEditingController groomController = TextEditingController();
  final TextEditingController brideController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  // final TextEditingController payController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
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
    // TODO: 저장 로직 추가
    setState(() {
      editMode = false;
    });
  }

  InputDecoration customInputDecoration({required String labelText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(editMode ? Icons.save : Icons.edit),
            onPressed: editMode ? saveChanges : toggleEditMode,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // TODO: 삭제 기능 추가 (ex. 다이얼로그 띄우기)
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
                  image: NetworkImage(widget.schedule.thumbnail),
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
                      Flexible(
                        child: TextField(
                          controller: groomController,
                          decoration: customInputDecoration(labelText: '신랑'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: TextField(
                          controller: brideController,
                          decoration: customInputDecoration(labelText: '신부'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : Text(
                    '👰‍♀️ ${widget.schedule.bride} & 🤵‍♂️ ${widget.schedule.groom}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

            const SizedBox(height: 8),

            editMode
                ? TextButton(
                    onPressed: () =>
                        _selectDateTime(context), // ✅ 날짜 + 시간 선택 함수
                    child: Text(
                      '📅 ${DateConverter.generateKrDate(selectedDate!.toIso8601String())} (수정)',
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  )
                : Text(
                    '📅 ${DateConverter.generateKrDate(widget.schedule.date)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

            // 🏡 장소 (수정 가능)
            editMode
                ? Flexible(
                    // width: 250,
                    child: TextField(
                      controller: locationController,
                      decoration: customInputDecoration(labelText: '장소'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : SizedBox(
                    width: 250,
                    child: Text(
                      '🏡 ${widget.schedule.location}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

            const SizedBox(height: 12),

            // 🔗 링크 열기 / 수정 가능
            editMode
                ? Flexible(
                    // width: 250,
                    child: TextField(
                      controller: linkController,
                      decoration: customInputDecoration(labelText: '링크'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : GestureDetector(
                    onTap: () async {
                      final Uri url = Uri.parse(widget.schedule.link);
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
            //         // '💰 축의금 ${widget.schedule.pay}만원',
            //         '💰 축의금 10만원',
            //         style: const TextStyle(
            //             fontSize: 16, fontWeight: FontWeight.bold),
            //       ),
          ],
        ),
      ),
    );
  }
}
