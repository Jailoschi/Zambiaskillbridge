import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/rules.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../discovery/discovery.dart' show pickOne;
import '../home/home_screens.dart' show JobCard;
import '../portfolio/portfolio.dart' show pickPhotos;

/// Third tab: Post Job for clients, My Work for workers.
class ActionScreen extends ConsumerWidget {
  const ActionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorker = ref.watch(appProvider.select((s) => s.isWorker));
    return isWorker ? const MyJobsScreen(title: 'My work') : const PostJobScreen();
  }
}

// ---------------------------------------------------------------------------
// Post a job
// ---------------------------------------------------------------------------

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});
  @override
  ConsumerState<PostJobScreen> createState() => _PostJobState();
}

class _PostJobState extends ConsumerState<PostJobScreen> {
  final _keys = List.generate(3, (_) => GlobalKey<FormState>());
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _hood = TextEditingController();
  final _min = TextEditingController();
  final _max = TextEditingController();
  int _step = 0;
  String _trade = kTrades.first.id;
  String _town = 'Lusaka';
  JobUrgency _urgency = JobUrgency.flexible;
  PricingType _pricing = PricingType.negotiable;
  String _contact = kContactMethods.first;
  DateTime? _date;
  List<String> _photos = [];
  String? _postedId;

  @override
  void dispose() {
    for (final c in [_title, _desc, _hood, _min, _max]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    _title.clear();
    _desc.clear();
    _hood.clear();
    _min.clear();
    _max.clear();
    setState(() {
      _step = 0;
      _trade = kTrades.first.id;
      _town = 'Lusaka';
      _urgency = JobUrgency.flexible;
      _pricing = PricingType.negotiable;
      _contact = kContactMethods.first;
      _date = null;
      _photos = [];
      _postedId = null;
    });
  }

  Job _draft() => Job(
        id: 'draft',
        title: _title.text.trim(),
        tradeId: _trade,
        description: _desc.text.trim(),
        province: provinceOfTown(_town),
        town: _town,
        neighbourhood: _hood.text.trim(),
        completeBy: _date == null ? '' : isoDay(_date!),
        urgency: _urgency,
        budgetMin: double.tryParse(_min.text.replaceAll(',', '').trim()),
        budgetMax: double.tryParse(_max.text.replaceAll(',', '').trim()),
        pricingPref: _pricing,
        photoPaths: _photos,
        contactMethod: _contact,
        clientId: '',
        clientName: '',
        postedAt: DateTime.now(),
      );

  void _next() {
    if (_step < 3 && !(_keys[_step].currentState?.validate() ?? true)) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      final id = ref.read(appProvider.notifier).postJob(_draft());
      setState(() => _postedId = id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_postedId != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job saved'), automaticallyImplyLeading: false),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 84, height: 84, decoration: const BoxDecoration(color: Color(0x1F21865B), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 46, color: SB.success)),
              const SizedBox(height: 18),
              const Text('Your job is saved', style: SB.h2),
              const SizedBox(height: 8),
              const Text('It now shows in My Jobs and to the demo workers on this device. It has not been published to a real marketplace.', textAlign: TextAlign.center, style: TextStyle(color: SB.text2, height: 1.4)),
              const SizedBox(height: 24),
              PrimaryButton('View my jobs', onPressed: () {
                final id = _postedId!;
                _reset();
                context.push('/job/$id');
              }),
              const SizedBox(height: 10),
              SecondaryButton('Post another job', onPressed: _reset),
            ]),
          ),
        ),
      );
    }
    final titles = ['Job details', 'Where and when', 'Budget and contact', 'Review'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Post a job · ${titles[_step]}'),
        automaticallyImplyLeading: false,
        leading: _step == 0 ? null : IconButton(tooltip: 'Previous step', icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step--)),
        actions: [TextButton(onPressed: () => context.push('/my-jobs'), child: const Text('My jobs'))],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(SB.pad, 0, SB.pad, 8),
            child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (_step + 1) / 4, minHeight: 6, backgroundColor: SB.soft, color: SB.navy)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 16 + MediaQuery.of(context).viewInsets.bottom),
              child: [_details, _where, _budget, _review][_step](),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 12), child: PrimaryButton(_step == 3 ? 'Submit job' : 'Continue', onPressed: _next)),
        ]),
      ),
    );
  }

  Widget _details() => Form(
        key: _keys[0],
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          TextFormField(controller: _title, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Job title', hintText: 'For example: Fix leaking kitchen tap'), validator: (v) => (v == null || v.trim().length < 5) ? 'Give the job a short title (at least 5 characters).' : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _trade,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Trade category'),
            items: [for (final t in kTrades) DropdownMenuItem(value: t.id, child: Text(t.name))],
            onChanged: (v) => setState(() => _trade = v ?? _trade),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _desc, minLines: 4, maxLines: 7, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Describe the work', alignLabelWithHint: true), validator: (v) => (v == null || v.trim().length < 20) ? 'Add more detail so workers understand the job (at least 20 characters).' : null),
        ]),
      );

  Widget _where() => Form(
        key: _keys[1],
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _town,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Town'),
            items: [for (final t in kAllTowns) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _town = v ?? _town),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _hood, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Neighbourhood or area (optional)')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await pickDate(context, initial: _date);
              if (d != null) setState(() => _date = d);
            },
            icon: const Icon(Icons.event),
            label: Text(_date == null ? 'Preferred completion date (optional)' : 'Finish by ${fmtDate(_date!)}'),
          ),
          FormSection('How urgent is it?', children: [ChipGroup<JobUrgency>(options: JobUrgency.values, selected: _urgency, label: (u) => u.label, onSelected: (v) => setState(() => _urgency = v ?? _urgency))]),
        ]),
      );

  Widget _budget() => Form(
        key: _keys[2],
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(controller: _min, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Budget from', prefixText: 'K '))),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _max,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Budget to', prefixText: 'K '),
                validator: (v) {
                  final a = double.tryParse(_min.text.trim());
                  final b = double.tryParse((v ?? '').trim());
                  if (a != null && b != null && b < a) return 'Must be at least the lower amount.';
                  return null;
                },
              ),
            ),
          ]),
          const Padding(padding: EdgeInsets.only(top: 6), child: Text('Budget is optional. Amounts are in Zambian kwacha.', style: TextStyle(fontSize: 12, color: SB.text2))),
          FormSection('Pricing preference', children: [ChipGroup<PricingType>(options: PricingType.values, selected: _pricing, label: (x) => x.label, onSelected: (v) => setState(() => _pricing = v ?? _pricing))]),
          FormSection('Preferred contact method', children: [ChipGroup<String>(options: kContactMethods, selected: _contact, label: (x) => x, onSelected: (v) => setState(() => _contact = v ?? _contact))]),
          FormSection('Photos (optional)', children: [
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final p in _photos)
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(fit: StackFit.expand, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: PortfolioImage(path: p, tradeId: _trade)),
                    Positioned(top: 0, right: 0, child: IconButton(tooltip: 'Remove photo', visualDensity: VisualDensity.compact, style: IconButton.styleFrom(backgroundColor: Colors.black54), icon: const Icon(Icons.close, size: 16, color: Colors.white), onPressed: () => setState(() => _photos.remove(p)))),
                  ]),
                ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final added = await pickPhotos(context, ref);
                  if (added.isNotEmpty) setState(() => _photos = [..._photos, ...added]);
                },
                child: Container(width: 80, height: 80, decoration: BoxDecoration(color: SB.soft, borderRadius: BorderRadius.circular(10), border: Border.all(color: SB.border)), child: const Icon(Icons.add_photo_alternate_outlined, color: SB.navy)),
              ),
            ]),
          ]),
        ]),
      );

  Widget _review() {
    final j = _draft();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      const Text('Check the details before you submit.', style: TextStyle(color: SB.text2)),
      const SizedBox(height: 10),
      SbCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(j.title, style: SB.h4),
          const SizedBox(height: 4),
          Text('${tradeById(j.tradeId).name} · ${j.location}', style: const TextStyle(color: SB.text2)),
          const SizedBox(height: 10),
          Text(j.description, style: const TextStyle(height: 1.4)),
          const Divider(height: 24),
          Text('Urgency: ${j.urgency.label}'),
          Text('Finish by: ${j.completeBy.isEmpty ? 'Not specified' : fmtIsoDay(j.completeBy)}'),
          Text('Budget: ${budgetText(j.budgetMin, j.budgetMax)} · ${j.pricingPref.label}'),
          Text('Contact: ${j.contactMethod}'),
          Text('Photos: ${j.photoPaths.length}'),
        ]),
      ),
      const SizedBox(height: 10),
      const InfoNote('Submitting saves the job on this device and shows it to the demo workers. Nothing is posted online.'),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Worker job discovery
// ---------------------------------------------------------------------------

class JobDiscoveryScreen extends ConsumerStatefulWidget {
  const JobDiscoveryScreen({super.key});
  @override
  ConsumerState<JobDiscoveryScreen> createState() => _JobDiscoveryState();
}

class _JobDiscoveryState extends ConsumerState<JobDiscoveryScreen> {
  final _q = TextEditingController();
  String? _trade;
  String? _town;
  double? _minBudget;
  JobUrgency? _urgency;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  bool get _hasFilters => _trade != null || _town != null || _minBudget != null || _urgency != null;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider);
    final text = _q.text.trim().toLowerCase();
    final jobs = s.jobs.where((j) {
      if (j.status != JobStatus.open) return false;
      if (_trade != null && j.tradeId != _trade) return false;
      if (_town != null && j.town != _town) return false;
      if (_urgency != null && j.urgency != _urgency) return false;
      if (_minBudget != null && (j.budgetMax ?? j.budgetMin ?? 0) < _minBudget!) return false;
      if (text.isNotEmpty && !('${j.title} ${j.description} ${tradeById(j.tradeId).name} ${j.town}'.toLowerCase().contains(text))) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    Widget chip(String label, bool on, VoidCallback tap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(label: Text(label), selected: on, showCheckmark: false, labelStyle: TextStyle(fontSize: 13, color: on ? Colors.white : SB.text), onSelected: (_) => tap()),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Find jobs'), automaticallyImplyLeading: false),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(SB.pad, 0, SB.pad, 8),
          child: TextField(controller: _q, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Search jobs', prefixIcon: Icon(Icons.search))),
        ),
        SizedBox(
          height: 46,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: SB.pad), children: [
            chip(_trade == null ? 'Trade' : tradeById(_trade!).name, _trade != null, () async {
              final t = await pickOne<TradeCategory>(context, title: 'Trade', options: kTrades, label: (t) => t.name, current: _trade == null ? null : tradeById(_trade!));
              setState(() => _trade = t?.id);
            }),
            chip(_town ?? 'Location', _town != null, () async {
              final t = await pickOne<String>(context, title: 'Location', options: kAllTowns, label: (x) => x, current: _town);
              setState(() => _town = t);
            }),
            chip(_minBudget == null ? 'Budget' : 'K${_minBudget!.round()}+', _minBudget != null, () async {
              final b = await pickOne<double>(context, title: 'Budget of at least', options: const [200, 500, 1000, 2000, 5000], label: (x) => zmw(x), current: _minBudget);
              setState(() => _minBudget = b);
            }),
            chip(_urgency == null ? 'Urgency' : _urgency!.label, _urgency != null, () async {
              final u = await pickOne<JobUrgency>(context, title: 'Urgency', options: JobUrgency.values, label: (x) => x.label, current: _urgency);
              setState(() => _urgency = u);
            }),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 0),
          child: Row(children: [
            Expanded(child: Text('${jobs.length} open job${jobs.length == 1 ? '' : 's'}', style: const TextStyle(color: SB.text2, fontSize: 13))),
            if (_hasFilters) TextButton(onPressed: () => setState(() { _trade = null; _town = null; _minBudget = null; _urgency = null; }), child: const Text('Clear filters')),
          ]),
        ),
        Expanded(
          child: jobs.isEmpty
              ? const EmptyState(icon: Icons.work_off_outlined, title: 'No jobs match', message: 'Try clearing a filter or checking again later.')
              : ListView(padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 24), children: [for (final j in jobs) JobCard(j)]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Job details
// ---------------------------------------------------------------------------

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});
  final String jobId;

  Future<void> _apply(BuildContext context, WidgetRef ref, Job job) async {
    final ctl = TextEditingController();
    final msg = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(c).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Apply for "${job.title}"', style: SB.h4),
          const SizedBox(height: 12),
          TextField(controller: ctl, minLines: 3, maxLines: 5, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Short message to the client', alignLabelWithHint: true)),
          const SizedBox(height: 14),
          PrimaryButton('Send application', onPressed: () => Navigator.pop(c, ctl.text)),
        ]),
      ),
    );
    if (msg == null || !context.mounted) return;
    final err = ref.read(appProvider.notifier).applyForJob(job.id, msg);
    showToast(context, err ?? 'Application saved. The client will see it in this demo.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final job = s.job(jobId);
    if (job == null) return Scaffold(appBar: AppBar(), body: const ErrorState(message: 'This job could not be found.'));
    final ctl = ref.read(appProvider.notifier);
    final owner = !s.isWorker && job.clientId == s.myClientId;
    final myApp = s.isWorker ? s.myApplication(job.id) : null;
    final applicants = s.applicationsForJob(job.id).where((a) => a.status != ApplicationStatus.withdrawn).toList();
    final accepted = applicants.where((a) => a.status == ApplicationStatus.accepted).toList();
    final trade = tradeById(job.tradeId);

    Widget actions;
    if (s.isWorker) {
      final noProfile = s.myWorker == null;
      if (myApp != null && myApp.status != ApplicationStatus.withdrawn) {
        actions = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [const Text('Application status:  ', style: TextStyle(fontWeight: FontWeight.w600)), StatusPill(myApp.status.label, color: applicationColor(myApp.status))]),
          const SizedBox(height: 10),
          if (myApp.status == ApplicationStatus.pending)
            SecondaryButton('Withdraw application', onPressed: () async {
              final ok = await confirmDialog(context, title: 'Withdraw application?', message: 'The client will no longer see it as pending.', confirmLabel: 'Withdraw', destructive: true);
              if (ok) ctl.withdrawApplication(myApp.id);
            }),
          if (myApp.status == ApplicationStatus.accepted)
            PrimaryButton('Message client', icon: Icons.chat_bubble_outline, onPressed: () {
              final id = ctl.openConversation(s.myWorkerId, clientId: job.clientId, clientName: job.clientName);
              context.push('/chat/$id');
            }),
        ]);
      } else if (job.status != JobStatus.open) {
        actions = const InfoNote('This job is no longer open for applications.');
      } else if (noProfile) {
        actions = Column(children: [const InfoNote('Set up your worker profile before applying.'), const SizedBox(height: 10), PrimaryButton('Set up profile', onPressed: () => context.push('/setup'))]);
      } else {
        actions = PrimaryButton(myApp == null ? 'Apply for job' : 'Apply again', onPressed: () => _apply(context, ref, job));
      }
    } else if (owner) {
      actions = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PrimaryButton('View applicants (${applicants.length})', icon: Icons.groups_outlined, onPressed: () => context.push('/applicants/${job.id}')),
        if (job.status == JobStatus.inProgress) ...[
          const SizedBox(height: 10),
          SecondaryButton('Mark as completed', icon: Icons.task_alt, onPressed: () async {
            final ok = await confirmDialog(context, title: 'Mark job as completed?', message: 'You will then be able to review the worker.', confirmLabel: 'Mark completed');
            if (ok) ctl.setJobStatus(job.id, JobStatus.completed);
          }),
        ],
        if (job.status == JobStatus.completed)
          for (final a in accepted) ...[
            const SizedBox(height: 10),
            if (s.worker(a.workerId) != null && !s.alreadyReviewed(job.id))
              PrimaryButton('Review ${s.worker(a.workerId)!.name}', icon: Icons.star_outline_rounded, onPressed: () => context.push('/review/${job.id}?workerId=${a.workerId}'))
            else
              const InfoNote('You have reviewed this job.', icon: Icons.check_circle_outline, color: SB.success),
          ],
        if (job.status == JobStatus.open || job.status == JobStatus.inProgress) ...[
          const SizedBox(height: 10),
          SecondaryButton('Cancel job', onPressed: () async {
            final ok = await confirmDialog(context, title: 'Cancel this job?', message: 'Workers will no longer be able to apply.', confirmLabel: 'Cancel job', destructive: true);
            if (ok) ctl.setJobStatus(job.id, JobStatus.cancelled);
          }),
        ],
      ]);
    } else {
      actions = const InfoNote('This job was posted by a demo client. Switch to the worker role to apply.');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: ListView(padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 24), children: [
        Row(children: [
          Expanded(child: Text(job.title, style: SB.h2)),
          const SizedBox(width: 8),
          StatusPill(job.status.label, color: job.status == JobStatus.cancelled ? SB.error : (job.status == JobStatus.completed ? SB.success : SB.accent)),
        ]),
        const SizedBox(height: 6),
        Text('${trade.name} · ${job.location}', style: const TextStyle(color: SB.text2)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 6, children: [
          StatusPill(job.urgency.label, color: urgencyColor(job.urgency), icon: Icons.schedule),
          StatusPill(budgetText(job.budgetMin, job.budgetMax), color: SB.navy, icon: Icons.payments_outlined),
          StatusPill(job.pricingPref.label, color: SB.blueGrey),
        ]),
        const SectionHeading('Description'),
        Text(job.description, style: const TextStyle(fontSize: 15, height: 1.5)),
        if (job.photoPaths.isNotEmpty) ...[
          const SectionHeading('Photos'),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: job.photoPaths.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 110, child: PortfolioImage(path: job.photoPaths[i], tradeId: job.tradeId))),
            ),
          ),
        ],
        const SectionHeading('Requirements'),
        SbCard(
          child: Column(children: [
            _row(Icons.event_outlined, 'Finish by', job.completeBy.isEmpty ? 'Not specified' : fmtIsoDay(job.completeBy)),
            _row(Icons.chat_outlined, 'Contact preference', job.contactMethod),
            _row(Icons.person_outline, job.isDemo ? 'Demo client' : 'Client', job.clientName),
            _row(Icons.history, 'Posted', timeAgo(job.postedAt)),
          ]),
        ),
        const SizedBox(height: 20),
        actions,
      ]),
    );
  }

  Widget _row(IconData i, String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(i, size: 19, color: SB.blueGrey),
          const SizedBox(width: 10),
          Text(l, style: const TextStyle(color: SB.text2)),
          const SizedBox(width: 10),
          Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}

class ApplicantsScreen extends ConsumerWidget {
  const ApplicantsScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final job = s.job(jobId);
    final ctl = ref.read(appProvider.notifier);
    if (job == null) return Scaffold(appBar: AppBar(), body: const ErrorState(message: 'This job could not be found.'));
    final apps = s.applicationsForJob(jobId).where((a) => a.status != ApplicationStatus.withdrawn).toList()..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    final canDecide = job.status == JobStatus.open && job.clientId == s.myClientId && !s.isWorker;
    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: apps.isEmpty
          ? EmptyState(icon: Icons.group_outlined, title: 'No applicants yet', message: 'Workers who apply for "${job.title}" will appear here.')
          : ListView(padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 24), children: [
              for (final a in apps)
                if (s.worker(a.workerId) != null)
                  Builder(builder: (context) {
                    final w = s.worker(a.workerId)!;
                    final r = s.ratingFor(w);
                    return SbCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Avatar(name: w.name, photoPath: w.photoPath, size: 48, colorValue: w.colorValue),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)), RatingRow(average: r.average, count: r.count, size: 14), VerificationChip(w)])),
                          StatusPill(a.status.label, color: applicationColor(a.status)),
                        ]),
                        if (a.message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('"${a.message}"', style: const TextStyle(height: 1.4))),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: SecondaryButton('View profile', onPressed: () => context.push('/worker/${w.id}'))),
                          if (canDecide && a.status == ApplicationStatus.pending) ...[
                            const SizedBox(width: 8),
                            IconButton.outlined(tooltip: 'Decline', color: SB.error, icon: const Icon(Icons.close), onPressed: () async {
                              final ok = await confirmDialog(context, title: 'Decline ${w.name}?', message: 'They will see that the application was declined.', confirmLabel: 'Decline', destructive: true);
                              if (ok) ctl.decideApplication(a.id, false);
                            }),
                            const SizedBox(width: 8),
                            IconButton.filled(tooltip: 'Accept', icon: const Icon(Icons.check), onPressed: () async {
                              final ok = await confirmDialog(context, title: 'Accept ${w.name}?', message: 'Other pending applicants will be declined and the job moves to In progress.', confirmLabel: 'Accept');
                              if (ok) ctl.decideApplication(a.id, true);
                            }),
                          ],
                        ]),
                      ]),
                    );
                  }),
            ]),
    );
  }
}

// ---------------------------------------------------------------------------
// My jobs and bookings
// ---------------------------------------------------------------------------

class _Entry {
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color color;
  final String route;
  final WorkBucket bucket;
  final DateTime when;
  final IconData icon;
  _Entry(this.title, this.subtitle, this.statusLabel, this.color, this.route, this.bucket, this.when, this.icon);
}

class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key, this.title = 'My jobs'});
  final String title;

  List<_Entry> _entries(AppState s) {
    final out = <_Entry>[];
    if (s.isWorker) {
      for (final a in s.applications.where((a) => a.workerId == s.myWorkerId)) {
        final j = s.job(a.jobId);
        if (j == null) continue;
        out.add(_Entry(j.title, 'Application · ${j.location}', a.status.label, applicationColor(a.status), '/job/${j.id}', bucketForApplication(a.status, j.status), a.appliedAt, Icons.assignment_outlined));
      }
      for (final b in s.bookings.where((b) => b.workerId == s.myWorkerId)) {
        out.add(_Entry(b.service, 'Booking · ${b.clientName}', b.status.label, bookingColor(b.status), '/booking/${b.id}', bucketForBooking(b.status), b.createdAt, Icons.event_available_outlined));
      }
    } else {
      for (final j in s.jobs.where((j) => j.clientId == s.myClientId)) {
        out.add(_Entry(j.title, 'Job post · ${j.location}', j.status.label, j.status == JobStatus.cancelled ? SB.error : (j.status == JobStatus.completed ? SB.success : SB.accent), '/job/${j.id}', bucketForJob(j.status), j.postedAt, Icons.work_outline));
      }
      for (final b in s.bookings.where((b) => b.clientId == s.myClientId)) {
        final w = s.worker(b.workerId);
        out.add(_Entry(b.service, 'Request to ${w?.name ?? 'worker'}', b.status.label, bookingColor(b.status), '/booking/${b.id}', bucketForBooking(b.status), b.createdAt, Icons.event_available_outlined));
      }
    }
    out.sort((a, b) => b.when.compareTo(a.when));
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final entries = _entries(s);
    const tabs = [(WorkBucket.active, 'Active'), (WorkBucket.pending, 'Pending'), (WorkBucket.completed, 'Completed'), (WorkBucket.cancelled, 'Cancelled')];
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(title: Text(title), bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [for (final t in tabs) Tab(text: '${t.$2} (${entries.where((e) => e.bucket == t.$1).length})')])),
        body: TabBarView(children: [
          for (final t in tabs)
            Builder(builder: (context) {
              final list = entries.where((e) => e.bucket == t.$1).toList();
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Nothing ${t.$2.toLowerCase()}',
                  message: s.isWorker ? 'Applications and bookings will show up here.' : 'Jobs you post and services you request will show up here.',
                  actionLabel: t.$1 == WorkBucket.active || t.$1 == WorkBucket.pending ? (s.isWorker ? 'Find jobs' : 'Post a job') : null,
                  onAction: () => context.go(s.isWorker ? '/discover' : '/action'),
                );
              }
              return ListView(padding: const EdgeInsets.fromLTRB(SB.pad, 12, SB.pad, 24), children: [
                for (final e in list)
                  SbCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    onTap: () => context.push(e.route),
                    child: Row(children: [
                      CircleAvatar(backgroundColor: SB.soft, child: Icon(e.icon, color: SB.navy, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), Text('${e.subtitle} · ${timeAgo(e.when)}', style: const TextStyle(fontSize: 12.5, color: SB.text2))])),
                      const SizedBox(width: 8),
                      StatusPill(e.statusLabel, color: e.color),
                    ]),
                  ),
              ]);
            }),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Booking details
// ---------------------------------------------------------------------------

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  String _actionLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.accepted:
        return 'Accept request';
      case BookingStatus.declined:
        return 'Decline';
      case BookingStatus.inProgress:
        return 'Start work';
      case BookingStatus.completed:
        return 'Mark as completed';
      case BookingStatus.cancelled:
        return 'Cancel';
      case BookingStatus.requested:
        return 'Request';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final b = s.booking(bookingId);
    if (b == null) return Scaffold(appBar: AppBar(), body: const ErrorState(message: 'This booking could not be found.'));
    final ctl = ref.read(appProvider.notifier);
    final w = s.worker(b.workerId);
    final next = allowedBookingTransitions(b.status, s.role);
    final reviewable = s.reviewableContexts(b.workerId).any((c) => c.id == b.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: ListView(padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 24), children: [
        Row(children: [
          Expanded(child: Text(b.service, style: SB.h2)),
          StatusPill(b.status.label, color: bookingColor(b.status)),
        ]),
        const SizedBox(height: 14),
        SbCard(
          child: Column(children: [
            _row(Icons.person_outline, s.isWorker ? 'Client' : 'Worker', s.isWorker ? b.clientName : (w?.name ?? 'Unknown')),
            _row(Icons.event_outlined, 'Preferred date', fmtDate(b.preferredDate)),
            _row(Icons.schedule, 'Preferred time', b.preferredTime),
            _row(Icons.place_outlined, 'Location', b.location),
            _row(Icons.payments_outlined, 'Budget', b.budget == null ? 'Not specified' : zmw(b.budget!)),
          ]),
        ),
        const SectionHeading('Job description'),
        Text(b.description, style: const TextStyle(height: 1.5)),
        if (b.notes.isNotEmpty) ...[const SectionHeading('Notes'), Text(b.notes, style: const TextStyle(height: 1.5))],
        const SectionHeading('Progress'),
        _Timeline(b.status),
        const SizedBox(height: 20),
        for (final n in next) ...[
          if (n == BookingStatus.declined || n == BookingStatus.cancelled)
            SecondaryButton(_actionLabel(n), onPressed: () async {
              final ok = await confirmDialog(context, title: '${_actionLabel(n)}?', message: 'This cannot be undone.', confirmLabel: _actionLabel(n), destructive: true);
              if (ok) ctl.setBookingStatus(b.id, n);
            })
          else
            PrimaryButton(_actionLabel(n), onPressed: () => ctl.setBookingStatus(b.id, n)),
          const SizedBox(height: 10),
        ],
        if (reviewable) PrimaryButton('Review ${w?.name ?? 'worker'}', icon: Icons.star_outline_rounded, onPressed: () => context.push('/review/${b.id}?workerId=${b.workerId}')),
        if (b.status == BookingStatus.completed && !s.isWorker && s.alreadyReviewed(b.id)) const InfoNote('You have reviewed this booking.', icon: Icons.check_circle_outline, color: SB.success),
        const SizedBox(height: 10),
        SecondaryButton(s.isWorker ? 'Message client' : 'Message worker', icon: Icons.chat_bubble_outline, onPressed: () {
          final id = s.isWorker ? ctl.openConversation(b.workerId, clientId: b.clientId, clientName: b.clientName) : ctl.openConversation(b.workerId);
          context.push('/chat/$id');
        }),
      ]),
    );
  }

  Widget _row(IconData i, String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(i, size: 19, color: SB.blueGrey),
          const SizedBox(width: 10),
          Text(l, style: const TextStyle(color: SB.text2)),
          const SizedBox(width: 10),
          Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}

class _Timeline extends StatelessWidget {
  const _Timeline(this.status);
  final BookingStatus status;
  @override
  Widget build(BuildContext context) {
    const flow = [BookingStatus.requested, BookingStatus.accepted, BookingStatus.inProgress, BookingStatus.completed];
    final ended = status == BookingStatus.declined || status == BookingStatus.cancelled;
    final idx = flow.indexOf(status);
    return Column(children: <Widget>[
      for (var i = 0; i < flow.length; i++)
        Row(children: [
          Icon(!ended && i <= idx ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: !ended && i <= idx ? SB.success : SB.border),
          const SizedBox(width: 10),
          Text(flow[i].label, style: TextStyle(fontWeight: !ended && i == idx ? FontWeight.w700 : FontWeight.w400, color: !ended && i <= idx ? SB.text : SB.text2)),
        ]),
      if (ended) Padding(padding: const EdgeInsets.only(top: 8), child: StatusPill('Ended: ${status.label}', color: SB.error, icon: Icons.block)),
    ].expand<Widget>((w) => [w, const SizedBox(height: 6)]).toList());
  }
}
