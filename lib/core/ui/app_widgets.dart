import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/money.dart';

/// Shared, professional building blocks used across feature screens so the UI
/// stays visually consistent (SPEC §89: no inline magic colors in features).

// ---------------------------------------------------------------------------
// KPI / summary tiles
// ---------------------------------------------------------------------------
class KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final String? hint;
  final Color? accent;

  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.hint,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive KPI grid (phone 1 col, tablet 2, desktop 4).
class KpiGrid extends StatelessWidget {
  final List<Widget> children;

  const KpiGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1024 ? 4 : (width >= 600 ? 2 : 1);
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      // Generous tiles so an icon badge, label, value and an optional hint all
      // fit on a phone without overflowing.
      childAspectRatio: columns == 1 ? 2.6 : 2.0,
      children: children,
    );
  }
}

// ---------------------------------------------------------------------------
// Sections & rows
// ---------------------------------------------------------------------------
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final Widget? valueWidget;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          valueWidget ??
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: emphasize
                      ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
                      : theme.textTheme.bodyMedium,
                ),
              ),
        ],
      ),
    );
  }
}

/// A colored status pill for any backend status string.
class StatusChip extends StatelessWidget {
  final String status;
  final String? label;

  const StatusChip({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color color;
    switch (status) {
      case 'active':
      case 'open':
      case 'paid':
      case 'received':
      case 'approved':
      case 'completed':
        color = Colors.green;
      case 'partially_paid':
      case 'partially_received':
      case 'submitted':
      case 'returned':
        color = Colors.orange;
      case 'unpaid':
      case 'draft':
      case 'in_transit':
      case 'invited':
        // 'invited' = the invite email is out, nobody has accepted yet.
        color = scheme.primary;
      case 'cancelled':
      case 'inactive':
      case 'archived':
      case 'suspended':
        color = scheme.error;
      default:
        color = scheme.outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        (label ?? status).replaceAll('_', ' '),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Simple horizontal bar used by reports (dependency-free chart).
class BarRow extends StatelessWidget {
  final String label;
  final String value;
  final double fraction; // 0..1
  final Color? color;

  const BarRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              Text(value, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color ?? scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form fields
// ---------------------------------------------------------------------------
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final bool autofocus;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AppDecimalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool allowNegative;
  final String requiredMessage;
  final String invalidMessage;
  final void Function(String)? onChanged;
  final bool enabled;

  const AppDecimalField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.allowNegative = false,
    this.requiredMessage = 'Required',
    this.invalidMessage = 'Invalid number',
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: required ? '$label *' : label),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return required ? requiredMessage : null;
        final parsed = Decimal.tryParse(v);
        if (parsed == null) return invalidMessage;
        if (!allowNegative && parsed < Decimal.zero) return invalidMessage;
        return null;
      },
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final bool required;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: required ? '$label *' : label),
    );
  }
}

/// A tappable date field with a Material date picker.
class AppDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null ? '' : DateFormat.yMMMd().format(value!);
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.event)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(text.isEmpty ? '—' : text),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback helpers
// ---------------------------------------------------------------------------
void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel ?? MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

String formatInt(num value) => NumberFormat.decimalPattern('en_PK').format(value);

/// Formats a money value trimmed to at most 2 decimals (display only).
String money(Decimal value) => formatMoney(value);
