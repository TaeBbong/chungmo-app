import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../presentation/theme/app_typography.dart';
import '../../presentation/theme/dimens.dart';
import '../../presentation/theme/palette.dart';

/// Coach mark tour over the home screen, shown once after onboarding.
///
/// [initTargets] builds either the full tour or, with `newFeaturesOnly`,
/// just the steps flagged as new — shown once to users who already saw an
/// older version of the tour before an update added steps.
class TutorialManager {
  final BuildContext context;
  final GlobalKey linkInputKey;
  final GlobalKey resultBodyKey;
  final GlobalKey statsPageKey;
  final GlobalKey calendarPageKey;

  late TutorialCoachMark _tutorialCoachMark;
  final List<TargetFocus> _targets = [];

  TutorialManager({
    required this.context,
    required this.linkInputKey,
    required this.resultBodyKey,
    required this.statsPageKey,
    required this.calendarPageKey,
  });

  @visibleForTesting
  int get targetCount => _targets.length;

  void initTargets({bool newFeaturesOnly = false}) {
    _targets.clear();

    final List<_StepSpec> steps = [
      _StepSpec(
        identify: 'link-input',
        key: linkInputKey,
        shape: ShapeLightFocus.RRect,
        radius: Dimens.radiusMd,
        align: ContentAlign.top,
        title: '청첩장을 붙여넣으세요',
        body: '링크나 문자를 붙여넣거나,\n사진 버튼으로 청첩장 이미지를 첨부해도 돼요.',
      ),
      _StepSpec(
        identify: 'result-body',
        key: resultBodyKey,
        shape: ShapeLightFocus.RRect,
        radius: Dimens.radiusMd,
        align: ContentAlign.bottom,
        title: 'AI가 알아서 정리해요',
        body: '날짜·장소·축의금 계좌까지\n분석 결과를 여기서 확인할 수 있어요.',
      ),
      _StepSpec(
        identify: 'stats-page',
        key: statsPageKey,
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
        title: '축의금은 AI가 추천해요',
        body: '일정에 관계를 기록하면 금액을 추천받고,\n낸 축의금은 여기서 통계로 확인해요.',
        isNewFeature: true,
      ),
      _StepSpec(
        identify: 'calendar-page',
        key: calendarPageKey,
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.right,
        padding: const EdgeInsets.fromLTRB(Dimens.md, Dimens.xxl, 0, 0),
        alignment: CrossAxisAlignment.start,
        title: '캘린더에서 한눈에',
        body: '등록된 일정은 여기를 눌러\n캘린더에서 확인해요.',
      ),
    ];

    final List<_StepSpec> visible =
        newFeaturesOnly ? steps.where((s) => s.isNewFeature).toList() : steps;

    for (int i = 0; i < visible.length; i++) {
      final _StepSpec spec = visible[i];
      final bool isLast = i == visible.length - 1;
      _targets.add(
        TargetFocus(
          identify: spec.identify,
          keyTarget: spec.key,
          shape: spec.shape,
          radius: spec.radius,
          contents: [
            TargetContent(
              align: spec.align,
              padding: spec.padding,
              builder: (context, controller) => _TooltipCard(
                step: i,
                totalSteps: visible.length,
                title: spec.title,
                body: spec.body,
                ctaLabel: isLast ? (newFeaturesOnly ? '확인' : '시작하기') : '다음',
                alignment: spec.alignment,
                onNext: isLast
                    ? () => _tutorialCoachMark.finish()
                    : controller.next,
                onSkip: controller.skip,
              ),
            ),
          ],
        ),
      );
    }
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

/// Declarative description of one tour step; [TutorialManager.initTargets]
/// turns the visible ones into [TargetFocus] entries with sequential dots.
class _StepSpec {
  final String identify;
  final GlobalKey key;
  final ShapeLightFocus shape;
  final double? radius;
  final ContentAlign align;
  final EdgeInsets padding;
  final CrossAxisAlignment alignment;
  final String title;
  final String body;
  final bool isNewFeature;

  const _StepSpec({
    required this.identify,
    required this.key,
    required this.shape,
    this.radius,
    required this.align,
    this.padding = const EdgeInsets.all(20.0),
    this.alignment = CrossAxisAlignment.center,
    required this.title,
    required this.body,
    this.isNewFeature = false,
  });
}

/// White rounded tooltip card with step dots, matching the app's card style.
class _TooltipCard extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String body;
  final String ctaLabel;
  final CrossAxisAlignment alignment;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TooltipCard({
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.body,
    required this.ctaLabel,
    this.alignment = CrossAxisAlignment.center,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    // The package hands content a tight full-remaining width; loosen it so
    // the card shrinks to its content instead of trailing empty space.
    return Align(
      alignment: alignment == CrossAxisAlignment.start
          ? Alignment.topLeft
          : Alignment.topCenter,
      child: Container(
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
            // A single-step tour (new-feature spotlight) needs no progress dots.
            if (totalSteps > 1) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalSteps, (i) {
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
            ],
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
                    padding: const EdgeInsets.symmetric(horizontal: Dimens.lg),
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
      ),
    );
  }
}
