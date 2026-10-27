import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../jobs/jobs.dart';

/// The second tab: Browse for clients, Find Jobs for workers.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorker = ref.watch(appProvider.select((s) => s.isWorker));
    return isWorker ? const JobDiscoveryScreen() : const BrowseTradesScreen();
  }
}

/// Bottom sheet that lets the user pick one value, with an optional "Any" row.
Future<T?> pickOne<T>(BuildContext context,
    {required String title,
    required List<T> options,
    required String Function(T) label,
    T? current,
    bool allowAny = true}) {
  return showModalBottomSheet<T?>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(c).size.height * .75),
        child: ListView(shrinkWrap: true, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title, style: SB.h4)),
          if (allowAny)
            ListTile(
              title: const Text('Any'),
              trailing: current == null
                  ? const Icon(Icons.check, color: SB.success)
                  : null,
              onTap: () => Navigator.pop(c, null),
            ),
          for (final o in options)
            ListTile(
              title: Text(label(o)),
              trailing: o == current
                  ? const Icon(Icons.check, color: SB.success)
                  : null,
              onTap: () => Navigator.pop(c, o),
            ),
        ]),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Browse trades (client tab)
// ---------------------------------------------------------------------------

class BrowseTradesScreen extends ConsumerStatefulWidget {
  const BrowseTradesScreen({super.key});
  @override
  ConsumerState<BrowseTradesScreen> createState() => _BrowseState();
}

class _BrowseState extends ConsumerState<BrowseTradesScreen> {
  final _q = TextEditingController();
  String? _town;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _qs({String? trade, String? q}) {
    final p = <String, String>{
      'trade': ?trade,
      if (q != null && q.isNotEmpty) 'q': q,
      'town': ?_town
    };
    return p.isEmpty
        ? '/search'
        : '/search?${p.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider);
    final text = _q.text.trim().toLowerCase();
    final trades = kTrades
        .where((t) =>
            text.isEmpty ||
            t.name.toLowerCase().contains(text) ||
            t.popularServices.any((x) => x.toLowerCase().contains(text)))
        .toList();
    final popular =
        kTrades.expand((t) => t.popularServices.take(1)).take(8).toList();
    final top = ref
        .read(searchRepoProvider)
        .search(s.workers, const SearchQuery(sort: SortMode.highestRated),
            rating: s.ratingFor)
        .take(3)
        .toList();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Browse trades'), automaticallyImplyLeading: false),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 24),
          children: [
            TextField(
              controller: _q,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => context.push(_qs(q: v.trim())),
              decoration: const InputDecoration(
                  hintText: 'Search by trade, skill or location',
                  prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.place_outlined, size: 18),
                label: Text(_town ?? 'All towns'),
                onPressed: () async {
                  final t = await pickOne<String>(context,
                      title: 'Choose a town',
                      options: kAllTowns,
                      label: (x) => x,
                      current: _town);
                  setState(() => _town = t);
                },
              ),
            ),
            if (s.viewedTrades.isNotEmpty) ...[
              const SectionHeading('Recently viewed'),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final id in s.viewedTrades)
                  ActionChip(
                    avatar: Icon(tradeById(id).icon, size: 18, color: SB.navy),
                    label: Text(tradeById(id).name),
                    onPressed: () => context.push(_qs(trade: id)),
                  ),
              ]),
            ],
            const SectionHeading('All trades'),
            if (trades.isEmpty)
              SizedBox(
                height: 280,
                child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching trades',
                    message: 'Try another word, or search workers directly.',
                    actionLabel: 'Search workers',
                    onAction: () => context.push(_qs(q: _q.text.trim()))),
              )
            else
              LayoutBuilder(builder: (c, box) {
                final w = (box.maxWidth - 10) / 2;
                return Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final t in trades)
                    SizedBox(
                        width: w,
                        child: TradeCard(t, onTap: () {
                          ref.read(appProvider.notifier).markViewedTrade(t.id);
                          context.push(_qs(trade: t.id));
                        })),
                ]);
              }),
            const SectionHeading('Top rated workers'),
            for (final w in top)
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WorkerRowCard(w)),
            const SectionHeading('Popular services'),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final p in popular)
                ActionChip(
                    label: Text(p), onPressed: () => context.push(_qs(q: p))),
            ]),
          ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Search results
// ---------------------------------------------------------------------------

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.trade, this.text, this.town});
  final String? trade;
  final String? text;
  final String? town;
  @override
  ConsumerState<SearchScreen> createState() => _SearchState();
}

class _SearchState extends ConsumerState<SearchScreen> {
  late final TextEditingController _ctl =
      TextEditingController(text: widget.text ?? '');
  late SearchQuery _q = SearchQuery(
      text: widget.text ?? '', tradeId: widget.trade, town: widget.town);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final repo = ref.read(searchRepoProvider);
    final st = ref.read(appProvider);
    final r = await showFilterSheet(context,
        initial: _q,
        countFor: (q) =>
            repo.search(st.workers, q, rating: st.ratingFor).length);
    if (r != null) setState(() => _q = r);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider);
    final results =
        ref.read(searchRepoProvider).search(s.workers, _q, rating: s.ratingFor);
    final sorts = [
      for (final m in SortMode.values)
        if (m != SortMode.nearestTown || _q.town != null) m
    ];
    return Scaffold(
      appBar: AppBar(
          title: Text(_q.tradeId == null
              ? 'Search workers'
              : tradeById(_q.tradeId!).name)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(SB.pad, 0, SB.pad, 8),
          child: TextField(
            controller: _ctl,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _q = _q.copyWith(text: v)),
            decoration: InputDecoration(
              hintText: 'Name, trade, skill or town',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _ctl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search text',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                            _ctl.clear();
                            _q = _q.copyWith(text: '');
                          })),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: SB.pad),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.tune, size: 18),
                    label: Text(_q.activeFilterCount > 0
                        ? 'Filters (${_q.activeFilterCount})'
                        : 'Filters'),
                    onPressed: _openFilters,
                  ),
                ),
                _chip(
                    _q.tradeId == null ? 'Trade' : tradeById(_q.tradeId!).name,
                    _q.tradeId != null, () async {
                  final t = await pickOne<TradeCategory>(context,
                      title: 'Trade',
                      options: kTrades,
                      label: (t) => t.name,
                      current:
                          _q.tradeId == null ? null : tradeById(_q.tradeId!));
                  setState(() =>
                      _q = _q.copyWith(tradeId: t?.id, clearTrade: t == null));
                }),
                _chip(_q.town ?? 'Location', _q.town != null, () async {
                  final t = await pickOne<String>(context,
                      title: 'Location',
                      options: kAllTowns,
                      label: (x) => x,
                      current: _q.town);
                  setState(() {
                    _q = _q.copyWith(town: t, clearTown: t == null);
                    if (t == null && _q.sort == SortMode.nearestTown) {
                      _q = _q.copyWith(sort: SortMode.bestMatch);
                    }
                  });
                }),
                _chip(
                    'Available now',
                    _q.availableOnly,
                    () => setState(() =>
                        _q = _q.copyWith(availableOnly: !_q.availableOnly))),
                _chip(_q.minRating > 0 ? '${_q.minRating}+ stars' : 'Rating',
                    _q.minRating > 0, () async {
                  final r = await pickOne<double>(context,
                      title: 'Minimum rating',
                      options: const [4.0, 4.5, 4.7],
                      label: (x) => '$x stars and above',
                      current: _q.minRating == 0 ? null : _q.minRating);
                  setState(() => _q = _q.copyWith(minRating: r ?? 0));
                }),
                _chip(
                    'Verified history',
                    _q.verifiedOnly,
                    () => setState(() =>
                        _q = _q.copyWith(verifiedOnly: !_q.verifiedOnly))),
                _chip(
                    _q.maxPrice != null
                        ? 'Up to ${zmw(_q.maxPrice!)}'
                        : 'Price',
                    _q.maxPrice != null, () async {
                  final p = await pickOne<double>(context,
                      title: 'Starting price up to',
                      options: const [150, 200, 250, 300, 500],
                      label: (x) => zmw(x),
                      current: _q.maxPrice);
                  setState(() =>
                      _q = _q.copyWith(maxPrice: p, clearPrice: p == null));
                }),
              ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 0),
          child: Row(children: [
            Expanded(
                child: Text(
                    '${results.length} worker${results.length == 1 ? '' : 's'} found',
                    style: const TextStyle(color: SB.text2, fontSize: 13))),
            if (_q.activeFilterCount > 0)
              TextButton(
                  onPressed: () => setState(
                      () => _q = SearchQuery(text: _q.text, sort: _q.sort)),
                  child: const Text('Clear filters')),
            PopupMenuButton<SortMode>(
              tooltip: 'Sort results',
              onSelected: (m) => setState(() => _q = _q.copyWith(sort: m)),
              itemBuilder: (_) => [
                for (final m in sorts)
                  CheckedPopupMenuItem(
                      value: m, checked: m == _q.sort, child: Text(m.label))
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 4),
                  Text(_q.sort.label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600))
                ]),
              ),
            ),
          ]),
        ),
        Expanded(
          child: results.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: 'No workers found',
                  message: 'Try removing a filter or searching a nearby town.',
                  actionLabel: 'Clear filters',
                  onAction: () => setState(() {
                        _ctl.clear();
                        _q = const SearchQuery();
                      }))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => FadeSlideIn(
                      key: ValueKey(results[i].id),
                      index: i,
                      child: WorkerCard(results[i])),
                ),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: active,
          showCheckmark: false,
          labelStyle:
              TextStyle(fontSize: 13, color: active ? Colors.white : SB.text),
          onSelected: (_) => onTap(),
        ),
      );
}

// ---------------------------------------------------------------------------
// Filter sheet
// ---------------------------------------------------------------------------

/// Full filter sheet. Returns the new query, or null if dismissed.
Future<SearchQuery?> showFilterSheet(BuildContext context,
    {required SearchQuery initial,
    required int Function(SearchQuery) countFor}) {
  return showModalBottomSheet<SearchQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FilterSheet(initial: initial, countFor: countFor),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.countFor});
  final SearchQuery initial;
  final int Function(SearchQuery) countFor;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchQuery _q = widget.initial;
  static const _maxSlider = 600.0;

  @override
  Widget build(BuildContext context) {
    final n = widget.countFor(_q);
    final price =
        (_q.maxPrice ?? _maxSlider).clamp(100.0, _maxSlider).toDouble();
    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .88),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(children: [
              const Expanded(child: Text('Filters', style: SB.h3)),
              TextButton(
                onPressed: () => setState(
                    () => _q = SearchQuery(text: _q.text, sort: _q.sort)),
                child: const Text('Reset'),
              ),
            ]),
          ),
          Flexible(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                shrinkWrap: true,
                children: [
                  FormSection('Trade', children: [
                    ChipGroup<TradeCategory>(
                      options: kTrades,
                      selected:
                          _q.tradeId == null ? null : tradeById(_q.tradeId!),
                      label: (t) => t.name,
                      onSelected: (t) => setState(() => _q =
                          _q.copyWith(tradeId: t?.id, clearTrade: t == null)),
                    ),
                  ]),
                  FormSection('Town', children: [
                    DropdownButtonFormField<String?>(
                      initialValue: _q.town,
                      isExpanded: true,
                      decoration: const InputDecoration(hintText: 'Any town'),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('Any town')),
                        for (final t in kAllTowns)
                          DropdownMenuItem<String?>(value: t, child: Text(t)),
                      ],
                      onChanged: (t) => setState(() =>
                          _q = _q.copyWith(town: t, clearTown: t == null)),
                    ),
                  ]),
                  FormSection(
                      _q.maxPrice == null
                          ? 'Starting price: any'
                          : 'Starting price: up to ${zmw(price)}',
                      children: [
                        Slider(
                          value: price,
                          min: 100,
                          max: _maxSlider,
                          divisions: 10,
                          label: price >= _maxSlider ? 'Any' : zmw(price),
                          onChanged: (v) => setState(() => _q = v >= _maxSlider
                              ? _q.copyWith(clearPrice: true)
                              : _q.copyWith(maxPrice: v)),
                        ),
                      ]),
                  FormSection('Minimum rating', children: [
                    ChipGroup<double>(
                      options: const [4.0, 4.5, 4.7],
                      selected: _q.minRating == 0 ? null : _q.minRating,
                      label: (r) => '$r+ stars',
                      onSelected: (r) =>
                          setState(() => _q = _q.copyWith(minRating: r ?? 0)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available now'),
                    value: _q.availableOnly,
                    onChanged: (v) =>
                        setState(() => _q = _q.copyWith(availableOnly: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Verified work history only'),
                    subtitle: const Text(
                        'Demo data. This is not an official credential.',
                        style: TextStyle(fontSize: 12)),
                    value: _q.verifiedOnly,
                    onChanged: (v) =>
                        setState(() => _q = _q.copyWith(verifiedOnly: v)),
                  ),
                ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: PrimaryButton(
                n == 0
                    ? 'No workers match'
                    : 'Show $n worker${n == 1 ? '' : 's'}',
                onPressed: n == 0 ? null : () => Navigator.pop(context, _q)),
          ),
        ]),
      ),
    );
  }
}
