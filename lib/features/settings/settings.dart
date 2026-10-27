import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../portfolio/portfolio.dart' show pickPhotos;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget _tile(IconData icon, String title, VoidCallback onTap, {String? subtitle, Widget? trailing}) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: SB.navy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final u = s.user;
    final ctl = ref.read(appProvider.notifier);
    if (u == null) return const Scaffold(body: LoadingState());
    final w = s.isWorker ? s.myWorker : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false),
      body: ListView(padding: const EdgeInsets.fromLTRB(SB.pad, 4, SB.pad, 32), children: [
        FadeSlideIn(
          child: ArchBackdrop(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Avatar(name: w?.name ?? u.name, photoPath: w?.photoPath ?? u.photoPath, size: 66)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w?.name ?? u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SB.h3.copyWith(color: Colors.white, fontSize: 22)),
                  if (u.phone.isNotEmpty) Text(u.phone, style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 13)),
                  if (u.email.isNotEmpty) Text(u.email, style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(s.isWorker ? 'Worker' : 'Client', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                    if (u.isDemo) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: SB.ochre, borderRadius: BorderRadius.circular(20)), child: const Text('Demo account', style: TextStyle(color: SB.text, fontSize: 12, fontWeight: FontWeight.w700))),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        const SectionHeading('Demo role'),
        SegmentedButton<UserRole>(
          segments: const [ButtonSegment(value: UserRole.worker, label: Text('Worker'), icon: Icon(Icons.engineering_outlined)), ButtonSegment(value: UserRole.client, label: Text('Client'), icon: Icon(Icons.person_search_outlined))],
          selected: {s.role},
          onSelectionChanged: (v) {
            ctl.switchRole(v.first);
            showToast(context, 'Switched to the ${v.first.name} experience.');
          },
        ),
        const SizedBox(height: 4),
        const Text('Lets you test both sides on one phone.', style: TextStyle(fontSize: 12, color: SB.text2)),
        const SectionHeading('Account'),
        _tile(Icons.edit_outlined, 'Edit personal details', () => context.push('/edit-profile')),
        _tile(Icons.photo_camera_outlined, 'Change profile photo', () async {
          final p = await pickPhotos(context, ref, multi: false);
          if (p.isNotEmpty) {
            ctl.updateUser(photoPath: p.first);
            if (w != null && u.isDemo) ctl.saveWorkerProfile(w.copyWith(photoPath: p.first));
          }
        }),
        if (s.isWorker) ...[
          _tile(Icons.person_outline, 'View public profile', () => s.myWorker == null ? context.push('/setup') : context.push('/worker/${s.myWorkerId}')),
          _tile(Icons.badge_outlined, s.myWorker == null ? 'Set up worker profile' : 'Edit worker profile', () => context.push('/setup')),
          _tile(Icons.photo_library_outlined, 'Manage portfolio', () => context.push('/portfolio')),
          _tile(Icons.event_available_outlined, 'Manage availability', () => context.push('/availability')),
          _tile(Icons.workspace_premium_outlined, 'Skills and badges', () => context.push('/badges')),
          _tile(Icons.quiz_outlined, 'Competency quizzes', () => context.push('/quizzes')),
        ] else ...[
          _tile(Icons.favorite_border, 'Saved workers', () => context.push('/favourites'), subtitle: '${s.favourites.length} saved'),
          _tile(Icons.work_outline, 'My jobs and bookings', () => context.push('/my-jobs')),
        ],
        _tile(Icons.school_outlined, 'Certification pathways', () => context.push('/certification')),
        _tile(Icons.notifications_none, 'Notifications', () => context.push('/notifications'), subtitle: s.unreadNotifications == 0 ? 'No unread' : '${s.unreadNotifications} unread'),
        const SectionHeading('Notification preferences'),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Jobs, applications and bookings'), value: s.settings.notifyJobs, onChanged: (v) => ctl.updateSettings(s.settings.copyWith(notifyJobs: v))),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Messages'), value: s.settings.notifyMessages, onChanged: (v) => ctl.updateSettings(s.settings.copyWith(notifyMessages: v))),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Reminders and badges'), value: s.settings.notifyReminders, onChanged: (v) => ctl.updateSettings(s.settings.copyWith(notifyReminders: v))),
        const SectionHeading('Data on this device'),
        SbCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.pending.length} change${s.pending.length == 1 ? '' : 's'} saved on this device only', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Nothing has been synchronised because there is no server yet.', style: TextStyle(color: SB.text2, fontSize: 13)),
            const SizedBox(height: 10),
            SecondaryButton('Check sync', icon: Icons.sync, onPressed: () async {
              final sync = ref.read(syncProvider);
              final r = await sync.sync(s.pending);
              if (context.mounted) showToast(context, r.message);
            }),
          ]),
        ),
        const SectionHeading('About'),
        _tile(Icons.privacy_tip_outlined, 'Privacy information', () => _privacy(context)),
        _tile(Icons.info_outline, 'About SkillBridge', () => _about(context), subtitle: 'Version $kAppVersion'),
        const SizedBox(height: 12),
        SecondaryButton('Clear demo data', icon: Icons.delete_sweep_outlined, onPressed: () async {
          final ok = await confirmDialog(context, title: 'Clear demo data?', message: 'This removes accounts, jobs, messages, reviews and photos stored by SkillBridge on this phone, then restores the sample data. Files outside the app are not touched.', confirmLabel: 'Clear data', destructive: true);
          if (!ok) return;
          await ctl.clearAllData();
          if (context.mounted) context.go('/intro');
        }),
        const SizedBox(height: 10),
        PrimaryButton('Sign out', icon: Icons.logout, onPressed: () async {
          final ok = await confirmDialog(context, title: 'Sign out?', message: 'Your data stays on this phone.', confirmLabel: 'Sign out');
          if (!ok) return;
          ctl.signOut();
          if (context.mounted) context.go('/role');
        }),
      ]),
    );
  }

  void _privacy(BuildContext context) => showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Privacy information'),
          content: const SingleChildScrollView(
            child: Text('This prototype keeps everything on your phone. Accounts, jobs, messages and photos are stored in the app and are not sent to a server.\n\nSample workers, clients and reviews are fictional.\n\nA real version would need secure sign in, protected storage for photos, server checks on every action, tools to report abuse, and a full privacy policy.', style: TextStyle(height: 1.45)),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
        ),
      );

  void _about(BuildContext context) => showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('About SkillBridge'),
          content: const SingleChildScrollView(
            child: Text('$kAppName. $kTagline\n\nShow it: make practical skills visible.\nProve it: reviews, quizzes and badges.\nGrow it: find work and learn about formal training.\n\nVersion $kAppVersion. A student prototype with demonstration data. Not affiliated with TEVETA or any authority.', style: TextStyle(height: 1.45)),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
        ),
      );
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: ref.read(appProvider).user?.name ?? '');
  late final _phone = TextEditingController(text: (ref.read(appProvider).user?.phone ?? '').replaceFirst('+260', '').trim());
  late final _email = TextEditingController(text: ref.read(appProvider).user?.email ?? '');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    ref.read(appProvider.notifier).updateUser(name: _name.text.trim(), phone: '+260${normaliseZmPhone(_phone.text)}', email: _email.text.trim());
    showToast(context, 'Details saved on this device.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Personal details')),
        body: Form(
          key: _form,
          child: ListView(padding: EdgeInsets.fromLTRB(SB.pad, 8, SB.pad, 24 + MediaQuery.of(context).viewInsets.bottom), children: [
            TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name.' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]'))], decoration: const InputDecoration(labelText: 'Phone number', prefixText: '+260  '), validator: (v) => normaliseZmPhone(v ?? '') == null ? 'Enter a valid Zambian mobile number.' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (optional)'), validator: (v) {
              final t = (v ?? '').trim();
              return t.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Enter a valid email address.';
            }),
            const SizedBox(height: 20),
            PrimaryButton('Save', onPressed: _save),
          ]),
        ),
      );
}

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final w = s.myWorker;
    final ctl = ref.read(appProvider.notifier);
    if (w == null) return Scaffold(appBar: AppBar(title: const Text('Availability')), body: EmptyState(icon: Icons.event_busy, title: 'No worker profile yet', message: 'Set up your profile to manage availability.', actionLabel: 'Start setup', onAction: () => context.push('/setup')));
    Future<void> time(bool start) async {
      final cur = (start ? w.hoursStart : w.hoursEnd).split(':');
      final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.tryParse(cur.first) ?? 8, minute: int.tryParse(cur.last) ?? 0));
      if (t == null) return;
      final v = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      ctl.saveWorkerProfile(start ? w.copyWith(hoursStart: v) : w.copyWith(hoursEnd: v));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Availability')),
      body: ListView(padding: const EdgeInsets.all(SB.pad), children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Available for new work', style: TextStyle(fontWeight: FontWeight.w700)), value: w.isAvailable, onChanged: (_) => ctl.toggleAvailable()),
        const SectionHeading('Days you work'),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final d in kWeekdays)
            FilterChip(
              label: Text(d),
              selected: w.days.contains(d),
              showCheckmark: false,
              labelStyle: TextStyle(color: w.days.contains(d) ? Colors.white : SB.text),
              onSelected: (on) => ctl.saveWorkerProfile(w.copyWith(days: on ? ([...w.days, d]..sort((a, b) => kWeekdays.indexOf(a).compareTo(kWeekdays.indexOf(b)))) : w.days.where((x) => x != d).toList())),
            ),
        ]),
        const SectionHeading('Working hours'),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => time(true), child: Text('From ${w.hoursStart}'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: () => time(false), child: Text('To ${w.hoursEnd}'))),
        ]),
        const SizedBox(height: 16),
        const InfoNote('Changes are saved on this device and show on your public profile.', icon: Icons.save_outlined),
      ]),
    );
  }
}

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final list = [for (final id in s.favourites) if (s.worker(id) != null) s.worker(id)!];
    return Scaffold(
      appBar: AppBar(title: const Text('Saved workers')),
      body: list.isEmpty
          ? EmptyState(icon: Icons.favorite_border, title: 'No saved workers yet', message: 'Tap the heart on a worker profile to keep them here.', actionLabel: 'Browse workers', onAction: () => context.go('/discover'))
          : ListView.separated(padding: const EdgeInsets.fromLTRB(SB.pad, 8, SB.pad, 24), itemCount: list.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, i) => WorkerRowCard(list[i])),
    );
  }
}
