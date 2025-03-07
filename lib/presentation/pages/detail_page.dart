// TODO: 일정 편집 기능(폼) / 축의금 금액 입력(db 필드 추가 및 업데이트) / 링크 필드도 넣기

import 'package:chungmo/presentation/widgets/schedule_detail_column.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/schedule.dart';

class DetailPage extends StatefulWidget {
  DetailPage({super.key});
  final Schedule schedule = Get.arguments as Schedule;

  @override
  // ignore: library_private_types_in_public_api
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: 수정 기능 추가
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // TODO: 삭제 기능 추가 (ex. 다이얼로그 띄우기)
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: 10,
            left: 30,
            child: Text('상세 일정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Center(child: ScheduleDetailColumn(schedule: widget.schedule)),
        ],
      ),
    );
  }
}
