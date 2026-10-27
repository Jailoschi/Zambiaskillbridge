import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorker = ref.watch(appProvider.select((s) => s.isWorker));
    return isWorker ? const WorkerHome() : const ClientHome();
  }
}

/// Avatar, greeting line, a second line, and the bell.
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.hello, required this.second, this.onTap});
  final String hello;
  final Widget second;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final w = s.isWorker ? s.myWorker : null;
    return Row(children: [
      InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.go('/profile'),
        child: Semantics(label: 'Open profile', button: true, child: Avatar(name: w?.name ?? s.user?.name ?? '', photoPath: w?.photoPath ?? s.user?.photoPath, size: 48)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hello, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: SB.text2)),
              const SizedBox(height: 2),
              second,
            ]),
          ),
        ),
      ),
      const _BellButton(),
    ]);
  }
}

/// Top of the worker dashboard: greeting and one key control.
class _Hero extends ConsumerWidget {
  const _Hero({required this.sub, this.child});
  final String sub;
  final Widget? child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(appProvider.select((s) => s.greetingName));
    return FadeSlideIn(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _TopBar(hello: greeting(), second: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        const SizedBox(height: 18),
        Text(sub, style: const TextStyle(color: SB.text2, fontSize: 14)),
        if (child != null) ...[const SizedBox(height: 10), child!],
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Worker
// ---------------------------------------------------------------------------

class WorkerHome extends ConsumerWidget {
  const WorkerHome({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final w = s.myWorker;
    final ctl = ref.read(appProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(SB.pad, 8, SB.pad, 24), children: [
          _Hero(
            sub: w == null ? 'Set up your profile to start getting work.' : 'Your profile is ${(w.completion * 100).round()}% complete.',
            child: w == null ? null : ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: w.completion, minHeight: 7, backgroundColor: SB.soft, color: SB.accent)),
          ),
          const SizedBox(height: 16),
          if (w == null) _setupCard(context) else ..._content(context, ref, s, w, ctl),
        ]),
      ),
    );
  }

  Widget _setupCard(BuildContext context) => SbCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Set up your worker profile', style: SB.h4),
          const SizedBox(height: 6),
          const Text('Add your trade, location and photos of past work so clients can find you.', style: TextStyle(color: SB.text2)),
          const SizedBox(height: 14),
          PrimaryButton('Start setup', onPressed: () => context.push('/setup')),
        ]),
      );

  List<Widget> _content(BuildContext context, WidgetRef ref, AppState s, WorkerProfile w, AppController ctl) {
    final r = s.ratingFor(w);
    final badges = s.badgesFor(w);
    final openJobs = s.jobs.where((j) => j.status == JobStatus.open && s.myApplication(j.id) == null).toList()
      ..sort((a, b) => (b.tradeId == w.tradeId ? 1 : 0).compareTo(a.tradeId == w.tradeId ? 1 : 0));
    final enquiries = s.bookings.where((b) => b.workerId == w.id).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final pct = (w.completion * 100).round();
    return [
      SbCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Profile completion', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: SB.navy)),
          ]),
          const SizedBox(height: 10),
          ProfileCompletionBar(w.completion),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: SecondaryButton('View public profile', onPressed: () => context.push('/worker/${w.id}'))),
            const SizedBox(width: 10),
            Expanded(child: SecondaryButton('Edit profile', onPressed: () => context.push('/setup'))),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      SbCard(
        padding: const EdgeInsets.symmetric(horizontal: SB.pad, vertical: 6),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(w.isAvailable ? 'Available for work' : 'Not taking new work', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Clients see this on your profile.'),
          value: w.isAvailable,
          onChanged: (_) => ctl.toggleAvailable(),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _Stat(icon: Icons.star_rounded, value: r.count == 0 ? '-' : r.average.toStringAsFixed(1), label: 'Rating')),
        const SizedBox(width: 10),
        Expanded(child: _Stat(icon: Icons.reviews_outlined, value: '${r.count}', label: 'Reviews')),
        const SizedBox(width: 10),
        Expanded(child: _Stat(icon: Icons.workspace_premium_outlined, value: '${badges.length}', label: 'Badges')),
      ]),
      const SizedBox(height: 16),
      PrimaryButton('Find Jobs', icon: Icons.search, warm: true, onPressed: () => context.go('/discover')),
      SectionHeading('Your skills', action: 'Edit', onAction: () => context.push('/setup')),
      SbCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${tradeById(w.tradeId).name} · ${w.skillLevel}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (w.skills.isEmpty)
            const Text('No skills added yet.', style: TextStyle(color: SB.text2))
          else
            Wrap(spacing: 8, runSpacing: 6, children: [for (final k in w.skills) Chip(label: Text(k.name))]),
          const SizedBox(height: 8),
          const Text('Skills you list are self-declared until backed by completed jobs or an external credential.', style: TextStyle(fontSize: 12, color: SB.text2)),
        ]),
      ),
      SectionHeading('Skill badges', action: 'See all', onAction: () => context.push('/badges')),
      SbCard(
        child: badges.isEmpty
            ? Row(children: [
                const Expanded(child: Text('No badges yet. Take a short quiz to earn your first one.', style: TextStyle(color: SB.text2))),
                TextButton(onPressed: () => context.push('/quizzes'), child: const Text('Take a quiz')),
              ])
            : Wrap(spacing: 4, runSpacing: 4, children: [for (final id in badges) SizedBox(width: 84, child: BadgeTile(badge: badgeById(id), earned: true))]),
      ),
      SectionHeading('Recommended jobs', action: 'More', onAction: () => context.go('/discover')),
      if (openJobs.isEmpty) const SbCard(child: Text('No open jobs right now.', style: TextStyle(color: SB.text2))),
      for (final j in openJobs.take(3)) JobCard(j),
      const SectionHeading('Recent client enquiries'),
      if (enquiries.isEmpty) const SbCard(child: Text('No service requests yet.', style: TextStyle(color: SB.text2))),
      for (final b in enquiries.take(3))
        SbCard(
          margin: const EdgeInsets.only(bottom: 10),
          onTap: () => context.push('/booking/${b.id}'),
          child: Row(children: [
            Avatar(name: b.clientName, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.service, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${b.clientName} · ${timeAgo(b.createdAt)}', style: const TextStyle(fontSize: 12.5, color: SB.text2)),
              ]),
            ),
            StatusPill(b.status.label, color: bookingColor(b.status)),
          ]),
        ),
      const SectionHeading('Recent activity'),
      ..._activity(context, s),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: SecondaryButton('Quizzes', icon: Icons.quiz_outlined, onPressed: () => context.push('/quizzes'))),
        const SizedBox(width: 10),
        Expanded(child: SecondaryButton('Certification', icon: Icons.school_outlined, onPressed: () => context.push('/certification'))),
      ]),
    ];
  }

  List<Widget> _activity(BuildContext context, AppState s) {
    final items = s.myNotifications.take(4).toList();
    if (items.isEmpty) return [const SbCard(child: Text('Nothing yet. Activity appears here.', style: TextStyle(color: SB.text2)))];
    return [
      for (final n in items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: SB.soft, child: Icon(notifIcon(n.type), color: SB.navy, size: 20)),
          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: Text(timeAgo(n.at), style: const TextStyle(fontSize: 11.5, color: SB.text2)),
          onTap: n.route == null ? null : () => context.push(n.route!),
        ),
    ];
  }
}

IconData notifIcon(NotifType t) {
  switch (t) {
    case NotifType.jobMatch:
      return Icons.work_outline;
    case NotifType.application:
    case NotifType.applicationStatus:
      return Icons.assignment_turned_in_outlined;
    case NotifType.serviceRequest:
    case NotifType.booking:
      return Icons.event_available_outlined;
    case NotifType.message:
      return Icons.chat_bubble_outline;
    case NotifType.reviewReminder:
      return Icons.star_outline_rounded;
    case NotifType.quiz:
      return Icons.workspace_premium_outlined;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => SbCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(children: [
          Icon(icon, color: SB.accent),
          const SizedBox(height: 4),
          Text(value, style: SB.h3),
          Text(label, style: const TextStyle(fontSize: 12, color: SB.text2)),
        ]),
      );
}

/// Job card shared by dashboards and job discovery, with the trade picture on the left.
class JobCard extends ConsumerWidget {
  const JobCard(this.job, {super.key});
  final Job job;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider.select((s) => s.isWorker ? s.myApplication(job.id) : null));
    return SbCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      onTap: () => context.push('/job/${job.id}'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 78, height: 96, child: TradeImage(job.tradeId))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(job.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700))),
              const SizedBox(width: 6),
              StatusPill(job.urgency.label, color: urgencyColor(job.urgency), icon: job.urgency == JobUrgency.urgent ? Icons.bolt : Icons.schedule),
            ]),
            const SizedBox(height: 3),
            Text('${tradeById(job.tradeId).name} · ${job.location}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: SB.text2)),
            const SizedBox(height: 5),
            Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.3)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Text(budgetText(job.budgetMin, job.budgetMax), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: SB.terracotta))),
              if (app != null) StatusPill(app.status.label, color: applicationColor(app.status)),
            ]),
            Text('${job.isDemo ? 'Demo client' : 'Client'}: ${job.clientName} · ${timeAgo(job.postedAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: SB.text2)),
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

class ClientHome extends ConsumerStatefulWidget {
  const ClientHome({super.key});
  @override
  ConsumerState<ClientHome> createState() => _ClientHomeState();
}

class _Banner {
  final String title;
  final String sub;
  final String cta;
  final String tradeId;
  final Color color;
  final String route;
  const _Banner(this.title, this.sub, this.cta, this.tradeId, this.color, this.route);
}

class _ClientHomeState extends ConsumerState<ClientHome> {
  final _q = TextEditingController();
  final _pages = PageController();
  String _town = 'Lusaka';
  int _page = 0;

  static const _banners = [
    _Banner('Top rated plumbers this week', 'Reviewed by clients in Lusaka', 'See plumbers', 'plumbing', SB.navy, '/search?trade=plumbing'),
    _Banner('Need a job done this week?', 'Post it and let workers come to you', 'Post a job', 'painting', AppColors.navyDark, '/action'),
    _Banner('Skilled welders on the Copperbelt', 'Kitwe and Ndola, ready to work', 'See welders', 'welding', Color(0xFF8A5A00), '/search?trade=welding'),
  ];

  @override
  void dispose() {
    _q.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _search() {
    final t = _q.text.trim();
    context.push(t.isEmpty ? '/search' : '/search?q=${Uri.encodeQueryComponent(t)}');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider);
    final repo = ref.read(searchRepoProvider);
    final nearby = repo.search(s.workers, SearchQuery(town: _town, sort: SortMode.highestRated), rating: s.ratingFor).take(8).toList();
    final suggested = repo.search(s.workers, const SearchQuery(sort: SortMode.highestRated, verifiedOnly: true), rating: s.ratingFor).take(3).toList();
    final viewed = [for (final id in s.viewedWorkers) if (s.worker(id) != null) s.worker(id)!];
    final myJobs = s.jobs.where((j) => j.clientId == s.myClientId).toList()..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(SB.pad, 10, SB.pad, 24), children: [
          _TopBar(
            hello: 'Hi, ${s.greetingName}',
            onTap: _pickTown,
            second: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.place, size: 16, color: SB.accent),
              const SizedBox(width: 4),
              Flexible(child: Text(_town, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5))),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _q,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'How can we help you today?',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(tooltip: 'Filters', icon: const Icon(Icons.tune), onPressed: () => context.push('/search')),
            ),
          ),
          const SectionHeading('This week'),
          SizedBox(
            height: 156,
            child: PageView.builder(
              controller: _pages,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final b = _banners[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => b.route == '/action' ? context.go('/action') : context.push(b.route),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: b.color, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 6, 14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2)),
                            const SizedBox(height: 4),
                            Text(b.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 12)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: Text(b.cta, maxLines: 1, style: TextStyle(color: b.color, fontWeight: FontWeight.w700, fontSize: 12.5)),
                            ),
                          ]),
                        ),
                      ),
                      SizedBox(
                        width: 132,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: ClipRRect(borderRadius: BorderRadius.circular(16), child: AppPhoto('assets/banners/banner_${i + 1}.jpg', fallbackTradeId: b.tradeId)),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _banners.length; i++)
              AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 3), width: i == _page ? 18 : 6, height: 6, decoration: BoxDecoration(color: i == _page ? SB.accent : SB.border, borderRadius: BorderRadius.circular(6))),
          ]),
          SectionHeading('Categories', action: 'See all', onAction: () => context.go('/discover')),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kTrades.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final t = kTrades[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    ref.read(appProvider.notifier).markViewedTrade(t.id);
                    context.push('/search?trade=${t.id}');
                  },
                  child: SizedBox(
                    width: 72,
                    child: Column(children: [
                      ClipOval(child: SizedBox(width: 64, height: 64, child: TradeImage(t.id))),
                      const SizedBox(height: 6),
                      Text(t.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.15)),
                    ]),
                  ),
                );
              },
            ),
          ),
          SectionHeading('Popular in $_town', action: 'See all', onAction: () => context.push('/search?town=${Uri.encodeQueryComponent(_town)}')),
          if (nearby.isEmpty)
            const Text('No workers listed in this town yet.', style: TextStyle(color: SB.text2))
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: nearby.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _PhotoWorker(nearby[i]),
              ),
            ),
          if (viewed.isNotEmpty) ...[
            const SectionHeading('Recently viewed'),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: viewed.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _PhotoWorker(viewed[i]),
              ),
            ),
          ],
          SectionHeading('Your job posts', action: 'View all', onAction: () => context.push('/my-jobs')),
          if (myJobs.isEmpty)
            const Text('You have not posted a job yet.', style: TextStyle(color: SB.text2))
          else
            for (final j in myJobs.take(3)) JobCard(j),
          const SectionHeading('Suggested professionals'),
          for (final w in suggested) Padding(padding: const EdgeInsets.only(bottom: 10), child: WorkerRowCard(w)),
        ]),
      ),
    );
  }

  Future<void> _pickTown() async {
    final t = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * .7),
          child: ListView(shrinkWrap: true, children: [
            for (final town in kAllTowns) ListTile(title: Text(town), trailing: town == _town ? const Icon(Icons.check, color: SB.success) : null, onTap: () => Navigator.pop(c, town)),
          ]),
        ),
      ),
    );
    if (t != null) setState(() => _town = t);
  }
}

class _BellButton extends ConsumerWidget {
  const _BellButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(appProvider.select((s) => s.unreadNotifications));
    return Tooltip(
      message: 'Notifications, $n unread',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push('/notifications'),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: SB.border)),
          child: Badge(label: Text('$n'), isLabelVisible: n > 0, child: const Icon(Icons.notifications_none, size: 24)),
        ),
      ),
    );
  }
}

/// Photo card for horizontal lists: picture, rating chip, name and trade over a gradient.
class _PhotoWorker extends ConsumerWidget {
  const _PhotoWorker(this.w);
  final WorkerProfile w;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(appProvider).ratingFor(w);
    return SizedBox(
      width: 230,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/worker/${w.id}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(fit: StackFit.expand, children: [
            WorkerPhoto(w),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xCC15202C)], stops: [.45, 1]))),
            Positioned(left: 10, top: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(20)), child: RatingRow(average: r.average, count: r.count, size: 13))),
            if (w.isAvailable) const Positioned(right: 10, top: 12, child: StatusPill('Available', color: SB.success)),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800)),
                Text('${tradeById(w.tradeId).name} · ${w.town}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 12.5)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
