import 'package:flutter/material.dart';

class BlogTopicFilter extends StatelessWidget {
  final List<String> topics;
  final String? selectedTopic;
  final ValueChanged<String?> onSelected;

  const BlogTopicFilter({
    super.key,
    required this.topics,
    required this.selectedTopic,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 7, 20, 9),
        children: [
          _chip(context, label: 'Todos', value: null),
          for (final topic in topics)
            _chip(context, label: topic, value: topic),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required String? value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = selectedTopic == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onSelected(value),
        labelStyle: TextStyle(
          color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        selectedColor: scheme.secondaryContainer,
        backgroundColor: scheme.surface,
        side: BorderSide(color: scheme.outline.withValues(alpha: .48)),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
