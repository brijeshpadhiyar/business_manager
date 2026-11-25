import 'dart:async';

import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/app_dialog.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/search/presentation/quick_actions.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/widgets/app_loader.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Opens the global search: one box that finds a lot, worker or process and
/// jumps to it. With an empty box it shows the quick actions, so it also works
/// as a launcher for everyday tasks (Ctrl+K on desktop and web).
Future<void> showGlobalSearch(BuildContext context) async {
  final router = GoRouter.of(context);
  final route = await AppDialog.showCustom<String>(
    context,
    builder: (_) => const GlobalSearchDialog(),
  );
  if (route != null) {
    await router.push<Object?>(route);
  }
}

/// The search dialog. Pops with the route to open, or null.
final class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

final class _SearchResults {
  const _SearchResults(this.lots, this.workers, this.processes);

  static const empty = _SearchResults([], [], []);

  final List<LotEntity> lots;
  final List<WorkerEntity> workers;
  final List<ProcessEntity> processes;

  bool get isEmpty => lots.isEmpty && workers.isEmpty && processes.isEmpty;
}

final class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  static const _maxPerSection = 6;

  final _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  bool _loading = false;
  _SearchResults _results = _SearchResults.empty;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      _requestId++;
      setState(() {
        _loading = false;
        _results = _SearchResults.empty;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 220), () => _search(query));
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    setState(() => _loading = true);
    try {
      final (lots, workers, processes) = await (
        getIt<LotRepository>().getLots(searchQuery: query),
        getIt<WorkerRepository>().getWorkers(searchQuery: query),
        getIt<ProcessRepository>().getProcesses(searchQuery: query),
      ).wait;
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _results = _SearchResults(
          lots.take(_maxPerSection).toList(),
          workers.take(_maxPerSection).toList(),
          processes.take(_maxPerSection).toList(),
        );
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _results = _SearchResults.empty;
      });
    }
  }

  void _open(String route) => Navigator.of(context).pop(route);

  void _openFirst() {
    final r = _results;
    if (r.lots.isNotEmpty) return _open(RoutePaths.lotDetail(r.lots.first.id));
    if (r.workers.isNotEmpty) {
      return _open(RoutePaths.workerDetail(r.workers.first.id));
    }
    if (r.processes.isNotEmpty) {
      return _open(RoutePaths.processDetail(r.processes.first.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final compact = AppBreakpoints.fromWidth(size.width).isCompact;
    final query = _controller.text.trim();

    final field = TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
      onSubmitted: (_) => _openFirst(),
      decoration: InputDecoration(
        hintText: l10n.uxSearchHint,
        prefixIcon: const Icon(AppIcons.search),
        suffixIcon: _loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: AppSpinner(size: 18, strokeWidth: 2),
              )
            : query.isEmpty
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: const Icon(AppIcons.close),
                onPressed: () {
                  _controller.clear();
                  _onChanged('');
                },
              ),
      ),
    );

    final List<Widget> body;
    if (query.isEmpty) {
      body = [
        _SectionTitle(l10n.uxQuickActions),
        for (final a in buildQuickActions(context))
          ListTile(
            leading: Icon(a.icon),
            title: Text(a.label),
            onTap: () => _open(a.route),
          ),
      ];
    } else if (!_loading && _results.isEmpty) {
      body = [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            l10n.uxSearchNoResults(query),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ];
    } else {
      body = [
        if (_results.lots.isNotEmpty) ...[
          _SectionTitle(l10n.uxSearchLots),
          for (final lot in _results.lots)
            ListTile(
              leading: const Icon(AppIcons.lot),
              title: Text(lot.lotNumber),
              subtitle: lot.title == null || lot.title!.isEmpty
                  ? null
                  : Text(lot.title!, maxLines: 1),
              onTap: () => _open(RoutePaths.lotDetail(lot.id)),
            ),
        ],
        if (_results.workers.isNotEmpty) ...[
          _SectionTitle(l10n.uxSearchWorkers),
          for (final w in _results.workers)
            ListTile(
              leading: const Icon(AppIcons.worker),
              title: Text(w.name),
              subtitle: w.phone == null || w.phone!.isEmpty
                  ? null
                  : Text(w.phone!),
              onTap: () => _open(RoutePaths.workerDetail(w.id)),
            ),
        ],
        if (_results.processes.isNotEmpty) ...[
          _SectionTitle(l10n.uxSearchProcesses),
          for (final p in _results.processes)
            ListTile(
              leading: const Icon(AppIcons.routeTransfer),
              title: Text(p.name),
              onTap: () => _open(RoutePaths.processDetail(p.id)),
            ),
        ],
      ];
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: field),
        const Divider(height: 1),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            children: body,
          ),
        ),
      ],
    );

    if (compact) {
      return Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(AppIcons.back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }
    return Dialog(
      alignment: const Alignment(0, -0.6),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: size.height * 0.7,
        ),
        child: content,
      ),
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
