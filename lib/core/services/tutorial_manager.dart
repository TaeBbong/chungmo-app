import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../presentation/theme/app_typography.dart';
import '../../presentation/theme/dimens.dart';
import '../../presentation/theme/palette.dart';

/// Coach mark tour over the home screen, shown once after onboarding.
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
        radius: Dimens.radiusMd,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _TooltipCard(
              step: 0,
              title: '청첩장을 붙여넣으세요',
              body: '링크나 문자를 붙여넣거나,\n사진 버튼으로 청첩장 이미지를 첨부해도 돼요.',
              ctaLabel: '다음',
              onNext: controller.next,
              onSkip: controller.skip,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "result-body",
        keyTarget: resultBodyKey,
        shape: ShapeLightFocus.RRect,
        radius: Dimens.radiusMd,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _TooltipCard(
              step: 1,
              title: 'AI가 알아서 정리해요',
              body: '날짜·장소·축의금 계좌까지\n분석 결과를 여기서 확인할 수 있어요.',
              ctaLabel: '다음',
              onNext: controller.next,
              onSkip: controller.skip,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "calendar-page",
        keyTarget: calendarPageKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            padding: const EdgeInsets.fromLTRB(Dimens.md, Dimens.xxl, 0, 0),
            align: ContentAlign.right,
            builder: (context, controller) => _TooltipCard(
              step: 2,
              title: '캘린더에서 한눈에',
              body: '등록된 일정은 여기를 눌러\n캘린더에서 확인해요.',
              ctaLabel: '시작하기',
              alignment: CrossAxisAlignment.start,
              onNext: () => _tutorialCoachMark.finish(),
              onSkip: controller.skip,
            ),
          ),
        ],
      ),
    ]);
  }

  void showTutorial() {
    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Palette.black,
      opacityShadow: 0.75,
      paddingFocus: 10,
      hideSkip: true,
      onSkip: () {
        return true;
      },
    );
    _tutorialCoachMark.show(context: context);
  }
}

/// White rounded tooltip card with step dots, matching the app's card style.
class _TooltipCard extends StatelessWidget {
  static const int _totalSteps = 3;

  final int step;
  final String title;
  final String body;
  final String ctaLabel;
  final CrossAxisAlignment alignment;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TooltipCard({
    required this.step,
    required this.title,
    required this.body,
    required this.ctaLabel,
    this.alignment = CrossAxisAlignment.center,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(Dimens.lg),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(Dimens.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_totalSteps, (i) {
              final bool active = i == step;
              return Container(
                margin: const EdgeInsets.only(right: 4),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? Palette.burgundy : Palette.grey250,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: Dimens.md),
          Text(
            title,
            style: AppTypography.title.copyWith(color: Palette.grey900),
            textAlign: alignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.left,
          ),
          const SizedBox(height: Dimens.sm),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(color: Palette.grey600),
            textAlign: alignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.left,
          ),
          const SizedBox(height: Dimens.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: Dimens.lg),
                ),
                child: Text(ctaLabel),
              ),
              const SizedBox(width: Dimens.sm),
              TextButton(
                onPressed: onSkip,
                child: const Text('건너뛰기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
