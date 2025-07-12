import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/schedule.dart';
import '../../core/utils/date_extension.dart';
import '../bloc/detail/detail_cubit.dart';
import '../../core/navigation/app_navigation.dart';

class DetailPage extends StatefulWidget {
  final Schedule schedule;
  const DetailPage({super.key, required this.schedule});

  @override
  // ignore: library_private_types_in_public_api
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool editMode = false;

  late final DetailCubit cubit;
  final TextEditingController groomController = TextEditingController();
  final TextEditingController brideController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  // final TextEditingController payController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    cubit = DetailCubit();
    cubit.setSchedule(widget.schedule);
    groomController.text = widget.schedule.groom;
    brideController.text = widget.schedule.bride;
    locationController.text = widget.schedule.location;
    linkController.text = widget.schedule.link;
    // payController.text = widget.schedule.pay;
    selectedDate = widget.schedule.date;
  }

  @override
  void dispose() {
    groomController.dispose();
    brideController.dispose();
    locationController.dispose();
    linkController.dispose();
    // payController.dispose();
    cubit.close();
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
          link: cubit.state.schedule!.link,
          thumbnail: cubit.state.schedule!.thumbnail,
          groom: groomController.text,
          bride: brideController.text,
          date: selectedDate!,
          location: locationController.text);
      cubit.editSchedule(editedSchedule);
      editMode = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정이 변경되었습니다.')),
      );
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
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
              cubit.deleteSchedule(cubit.state.schedule!.link);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일정이 삭제되었습니다.')),
              );
              navigatorKey.currentState
                  ?.popUntil((route) => route.settings.name == '/calendar');
            },
            child: const Text("삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DetailCubit>.value(
      value: cubit,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          navigatorKey.currentState
              ?.popUntil((route) => route.settings.name == '/calendar');
        },
        child: SafeArea(
          top: false,
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
                            cubit.state.schedule!.thumbnail),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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
                          '🤵‍♂️ ${cubit.state.schedule!.groom} & 👰‍♀️ ${cubit.state.schedule!.bride}',
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
                              text: selectedDate!.krDate,
                            ), // 날짜를 TextField에 표시
                            decoration: customInputDecoration(
                              labelText: '날짜',
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : Text(
                          '📅 ${cubit.state.schedule!.date.krDate}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
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
                            '🏡 ${cubit.state.schedule!.location}',
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
                                Uri.parse(cubit.state.schedule!.link);
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
        ),
      ),
    );
  }
}
