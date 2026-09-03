import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// The compact choice chip used by the record and edit forms.
///
/// Extracted so every selection row (attendance, relation, pay presets)
/// shares one look.
class SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      // The default selected color comes from the theme's secondaryContainer,
      // which is off-palette.
      selectedColor: isLight ? Palette.burgundy50 : Palette.burgundy600,
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected
            ? (isLight ? Palette.burgundy : Palette.burgundy100)
            : (isLight ? Palette.grey700 : Palette.grey400),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => onSelected(),
    );
  }
}
