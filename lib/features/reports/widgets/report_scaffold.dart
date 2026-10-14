import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/async_view.dart';
import '../../setup/providers/branch_provider.dart';
import '../export/report_pdf.dart';
import '../providers/report_providers.dart';

enum _Preset { today, yesterday, last7, last30, thisMonth, custom }

/// The date window a report currently shows.
class ReportWindow {
  final DateTime from;
  final DateTime to;
  final String? branchId;

  const ReportWindow({required this.from, required this.to, this.branchId});

  ReportRange toRange() => ReportRange(from: from, to: to, branchId: branchId);
}

/// Shared report chrome: title, date presets, branch filter, refresh and the
/// loading/empty/error states — every report renders inside this (SPEC §87).
class ReportScaffold extends ConsumerStatefulWidget {
  final String title;
  final Widget Function(BuildContext context, WidgetRef ref, ReportWindow window) body;
  final List<Widget> actions;
  final bool showDateRange;
  final bool showBranch;

  const ReportScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showDateRange = true,
    this.showBranch = true,
  });

  @override
  ConsumerState<ReportScaffold> createState() => _ReportScaffoldState();
}

class _ReportScaffoldState extends ConsumerState<ReportScaffold> {
  late DateTime _from;
  late DateTime _to;
  _Preset _preset = _Preset.last7;
  String? _branchId;

  @override
  void initState() {
    super.initState();
    _applyPreset(_Preset.last7);
  }

  void _applyPreset(_Preset preset) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    setState(() {
      _preset = preset;
      switch (preset) {
        case _Preset.today:
          _from = DateTime(now.year, now.month, now.day);
          _to = endOfToday;
        case _Preset.yesterday:
          final y = now.subtract(const Duration(days: 1));
          _from = DateTime(y.year, y.month, y.day);
          _to = DateTime(y.year, y.month, y.day, 23, 59, 59);
        case _Preset.last7:
          _from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
          _to = endOfToday;
        case _Preset.last30:
          _from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
          _to = endOfToday;
        case _Preset.thisMonth:
          _from = DateTime(now.year, now.month, 1);
          _to = endOfToday;
        case _Preset.custom:
          break;
      }
    });
  }

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked == null) return;
    setState(() {
      _preset = _Preset.custom;
      _from = DateTime(picked.start.year, picked.start.month, picked.start.day);
      _to = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final branches = ref.watch(branchesProvider).valueOrNull ?? const [];
    final fmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ...widget.actions,
          IconButton(
            tooltip: l10n.retry,
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.showDateRange)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _presetChip(l10n.today, _Preset.today),
                      _presetChip(l10n.yesterday, _Preset.yesterday),
                      _presetChip(l10n.last7Days, _Preset.last7),
                      _presetChip(l10n.last30Days, _Preset.last30),
                      _presetChip(l10n.thisMonth, _Preset.thisMonth),
                      ActionChip(
                        avatar: const Icon(Icons.event, size: 16),
                        label: Text(
                          _preset == _Preset.custom
                              ? '${fmt.format(_from)} – ${fmt.format(_to)}'
                              : l10n.dateRange,
                        ),
                        onPressed: _pickCustom,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (widget.showBranch && branches.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonFormField<String?>(
                initialValue: _branchId,
                isDense: true,
                decoration: InputDecoration(labelText: l10n.branch),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.statusAll)),
                  for (final b in branches) DropdownMenuItem(value: b.id, child: Text(b.name)),
                ],
                onChanged: (v) => setState(() => _branchId = v),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.body(
              context,
              ref,
              ReportWindow(from: _from, to: _to, branchId: _branchId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, _Preset preset) {
    return ChoiceChip(
      label: Text(label),
      selected: _preset == preset,
      onSelected: (_) => _applyPreset(preset),
    );
  }
}

/// Standard "Export PDF" action used by every report screen (SPEC §20).
class ReportExportButton extends StatelessWidget {
  final ExportTable Function() table;

  const ReportExportButton({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => shareReportPdf(table()),
      icon: const Icon(Icons.picture_as_pdf_outlined),
      label: Text(context.l10n.exportPdf),
    );
  }
}

/// Wraps an [AsyncValue] report in the standard states, keeping the whole body
/// scrollable so pull-to-refresh works even when empty/error (SPEC §87).
class ReportBody<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;

  const ReportBody({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: value.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => ErrorState(
          message: error is AppException ? error.message : l10n.somethingWentWrong,
          onRetry: onRetry,
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [builder(data)],
        ),
      ),
    );
  }
}
