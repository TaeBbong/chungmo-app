import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialManager {
  final BuildContext context;
  final GlobalKey linkInputKey;
  final GlobalKey resultBodyKey;
  final GlobalKey calendarPageKey;

  late TutorialCoachMark _tutorialCoachMark;
  final List<TargetFocus> _targets = [];

  TutorialManager({
    required this.context,
    required this.linkInputKey,
    required this.resultBodyKey,
    required this.calendarPageKey,
  });

  void initTargets() {
    _targets.clear();
    _targets.addAll([
      TargetFocus(
        identify: "link-input",
        keyTarget: linkInputKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Step 1 : 링크 입력",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "지인에게 받은 모바일 청첩장 링크를\n여기에 붙여넣으세요!",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _tutorialCoachMark.next();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "다음 (1/3)",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _tutorialCoachMark.skip();
                      },
                      child: const Text(
                        '건너뛰기',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "result-body",
        keyTarget: resultBodyKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Step 2 : 분석 결과 확인",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "AI가 분석한 결과를 여기서 확인할 수 있어요!",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _tutorialCoachMark.next();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "다음 (2/3)",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _tutorialCoachMark.skip();
                      },
                      child: const Text(
                        '건너뛰기',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "calendar-page",
        keyTarget: calendarPageKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            padding: const EdgeInsets.fromLTRB(16, 48, 0, 0),
            align: ContentAlign.right,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Step 3 : 캘린더로 이동",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "등록된 일정을 확인하려면\n여기를 눌러 캘린더로 이동해요.",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _tutorialCoachMark.finish();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "완료 (3/3)",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _tutorialCoachMark.skip();
                      },
                      child: const Text(
                        '건너뛰기',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  void showTutorial() {
    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 10,
      hideSkip: true,
      onSkip: () {
        return true;
      },
    );
    _tutorialCoachMark.show(context: context);
  }
}
