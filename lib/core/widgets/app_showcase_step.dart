import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../constants/app_colors.dart';

class AppShowcaseStep extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final EdgeInsets targetPadding;
  final BorderRadius targetBorderRadius;
  final TooltipPosition? tooltipPosition;

  const AppShowcaseStep({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.targetPadding = const EdgeInsets.all(6),
    this.targetBorderRadius = const BorderRadius.all(Radius.circular(20)),
    this.tooltipPosition,
  });

  static TooltipActionConfig get actionConfig => const TooltipActionConfig(
    alignment: MainAxisAlignment.spaceBetween,
    gapBetweenContentAndAction: 14,
  );

  static List<TooltipActionButton> actions(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800);

    return [
      TooltipActionButton(
        type: TooltipDefaultActionType.skip,
        name: 'Saltar',
        backgroundColor: AppColors.background,
        textStyle: labelStyle?.copyWith(color: AppColors.textSecondary),
      ),
      TooltipActionButton(
        type: TooltipDefaultActionType.previous,
        name: 'Atrás',
        backgroundColor: AppColors.white,
        border: Border.all(color: AppColors.lightGray),
        textStyle: labelStyle?.copyWith(color: AppColors.navy),
      ),
      TooltipActionButton(
        type: TooltipDefaultActionType.next,
        name: 'Siguiente',
        backgroundColor: AppColors.teal,
        textStyle: labelStyle?.copyWith(color: AppColors.white),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      tooltipBackgroundColor: AppColors.white,
      tooltipBorderRadius: BorderRadius.circular(18),
      tooltipPadding: const EdgeInsets.all(16),
      overlayColor: AppColors.navy,
      overlayOpacity: 0.62,
      blurValue: 1,
      targetPadding: targetPadding,
      targetBorderRadius: targetBorderRadius,
      tooltipPosition: tooltipPosition,
      showArrow: true,
      titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.navy,
        fontWeight: FontWeight.w900,
      ),
      descTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      tooltipActionConfig: actionConfig,
      tooltipActions: actions(context),
      child: child,
    );
  }
}
