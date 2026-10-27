import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../constants/constants.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------

/// Vector SkillBridge mark: a bridge arch with hangers on a navy tile.
class SbLogo extends StatelessWidget {
  const SbLogo({super.key, this.size = 40, this.wordmark = true, this.light = false});
  final double size;
  final bool wordmark;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final mark = Semantics(
      label: 'SkillBridge logo',
      child: SizedBox(width: size, height: size, child: CustomPaint(painter: _MarkPainter(light))),
    );
    if (!wordmark) return mark;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      mark,
      SizedBox(width: size * .28),
      Text('SkillBridge', style: TextStyle(fontSize: size * .5, fontWeight: FontWeight.w800, color: light ? Colors.white : SB.navy, letterSpacing: -.3)),
    ]);
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.light);
  final bool light;
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * .26)), Paint()..color = light ? Colors.white : SB.navy);
    final p = Paint()
      ..color = light ? SB.navy : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * .18, s * .68), Offset(s * .82, s * .68), p);
    canvas.drawPath(Path()..moveTo(s * .22, s * .68)..quadraticBezierTo(s * .5, s * .16, s * .78, s * .68), p);
    double y(double t) => (1 - t) * (1 - t) * .68 + 2 * t * (1 - t) * .16 + t * t * .68;
    for (final t in [.28, .5, .72]) {
      final x = .22 + .56 * t;
      canvas.drawLine(Offset(s * x, s * y(t)), Offset(s * x, s * .68), p..strokeWidth = s * .045);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.light != light;
}

// ---------------------------------------------------------------------------
// Basic building blocks
// ---------------------------------------------------------------------------

class SbCard extends StatelessWidget {
  const SbCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(SB.pad), this.margin});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: SB.card,
        borderRadius: BorderRadius.circular(SB.radius),
        border: Border.all(color: SB.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SB.radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return box;
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
        child: Row(children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: SB.h4))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, this.onPressed, this.icon, this.busy = false, this.expand = true, this.warm = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;
  final bool warm;
  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ]);
    final b = FilledButton(
      onPressed: busy ? null : onPressed,
      style: warm ? FilledButton.styleFrom(backgroundColor: SB.terracotta) : null,
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: b) : b;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(this.label, {super.key, this.onPressed, this.icon, this.expand = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  @override
  Widget build(BuildContext context) {
    final b = OutlinedButton(
      onPressed: onPressed,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ]),
    );
    return expand ? SizedBox(width: double.infinity, child: b) : b;
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color = SB.accent, this.icon});
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Flexible(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis)),
        ]),
      );
}

Color bookingColor(BookingStatus s) {
  switch (s) {
    case BookingStatus.accepted:
    case BookingStatus.completed:
      return SB.success;
    case BookingStatus.inProgress:
      return SB.accent;
    case BookingStatus.requested:
      return SB.warning;
    case BookingStatus.declined:
    case BookingStatus.cancelled:
      return SB.error;
  }
}

Color applicationColor(ApplicationStatus s) {
  switch (s) {
    case ApplicationStatus.accepted:
      return SB.success;
    case ApplicationStatus.pending:
      return SB.warning;
    case ApplicationStatus.declined:
      return SB.error;
    case ApplicationStatus.withdrawn:
      return SB.text2;
  }
}

Color urgencyColor(JobUrgency u) => u == JobUrgency.urgent ? SB.error : (u == JobUrgency.soon ? SB.warning : SB.success);

class Avatar extends ConsumerWidget {
  const Avatar({super.key, required this.name, this.photoPath, this.size = 48, this.colorValue = 0xFFEAF0F6});
  final String name;
  final String? photoPath;
  final double size;
  final int colorValue;
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Color(colorValue), shape: BoxShape.circle),
      child: Text(_initials, style: TextStyle(fontSize: size * .36, fontWeight: FontWeight.w700, color: SB.navy)),
    );
    if (photoPath != null) {
      return ClipOval(
        child: Image.file(File(photoPath!), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
      );
    }
    final key = name.trim().toLowerCase();
    WorkerProfile? match;
    if (key.isNotEmpty) {
      for (final x in ref.watch(appProvider.select((s) => s.workers))) {
        if (x.name.trim().toLowerCase() == key) {
          match = x;
          break;
        }
      }
    }
    if (match == null) return Semantics(label: 'Photo of $name', child: fallback);
    return Semantics(label: 'Photo of $name', child: ClipOval(child: SizedBox(width: size, height: size, child: WorkerPhoto(match))));
  }
}

/// Illustrated picture for a trade. Replace the files in assets/trades/ with real photos
/// (same file names) to change them everywhere.
class TradeImage extends StatelessWidget {
  const TradeImage(this.tradeId, {super.key, this.fit = BoxFit.cover});
  final String tradeId;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/trades/$tradeId.png',
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => Container(color: tradeColor(tradeId).withValues(alpha: .13), alignment: Alignment.center, child: Icon(tradeById(tradeId).icon, size: 34, color: tradeColor(tradeId))),
      );
}

/// Shows a stored photo when the file exists, otherwise the trade picture.
class PortfolioImage extends StatelessWidget {
  const PortfolioImage({super.key, this.path, required this.tradeId, this.fit = BoxFit.cover});
  final String? path;
  final String tradeId;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final ph = TradeImage(tradeId, fit: fit);
    if (path == null) return ph;
    return Image.file(File(path!), fit: fit, width: double.infinity, height: double.infinity, errorBuilder: (_, _, _) => ph);
  }
}

class RatingRow extends StatelessWidget {
  const RatingRow({super.key, required this.average, required this.count, this.size = 16});
  final double average;
  final int count;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (count == 0) return const Text('No reviews yet', style: TextStyle(fontSize: 12.5, color: SB.text2));
    return Semantics(
      label: '${average.toStringAsFixed(1)} out of 5 stars from $count reviews',
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_rounded, size: size + 2, color: const Color(0xFFE0A21B)),
          const SizedBox(width: 3),
          Text(average.toStringAsFixed(1), style: TextStyle(fontSize: size - 2, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text('($count)', style: TextStyle(fontSize: size - 3, color: SB.text2)),
        ]),
      ),
    );
  }
}

class StarInput extends StatelessWidget {
  const StarInput({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i star${i == 1 ? '' : 's'}',
            iconSize: 38,
            onPressed: () => onChanged(i),
            icon: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFE0A21B)),
          ),
      ]);
}

/// Spells out what a worker's status actually means. Never implies official certification.
class VerificationChip extends StatelessWidget {
  const VerificationChip(this.w, {super.key});
  final WorkerProfile w;
  @override
  Widget build(BuildContext context) {
    if (w.externalCredentials.isNotEmpty) {
      return const StatusPill('External credential on record', color: SB.success, icon: Icons.verified);
    }
    if (w.verifiedHistory) {
      return const StatusPill('Verified work history (demo)', color: SB.success, icon: Icons.task_alt);
    }
    return const StatusPill('Self-declared skills', color: SB.text2, icon: Icons.person_outline);
  }
}

class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge, required this.earned, this.onTap});
  final SkillBadge badge;
  final bool earned;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        label: '${badge.name}, ${earned ? 'earned' : 'not yet earned'}',
        button: onTap != null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: earned ? SB.navy : SB.soft, shape: BoxShape.circle),
                child: Icon(earned ? badge.icon : Icons.lock_outline, color: earned ? Colors.white : SB.text2, size: 26),
              ),
              const SizedBox(height: 6),
              Text(badge.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: earned ? SB.text : SB.text2)),
            ]),
          ),
        ),
      );
}

class ProfileCompletionBar extends StatelessWidget {
  const ProfileCompletionBar(this.value, {super.key});
  final double value;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Profile ${(value * 100).round()} percent complete',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: SB.soft, color: SB.accent),
          ),
        ]),
      );
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: SB.soft, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: SB.blueGrey),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: SB.h4),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: SB.text2, height: 1.4)),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              PrimaryButton(actionLabel!, onPressed: onAction, expand: false),
            ],
          ]),
        ),
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message = 'Something went wrong. Please try again.', this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(icon: Icons.error_outline, title: 'We hit a problem', message: message, actionLabel: onRetry == null ? null : 'Try again', onAction: onRetry);
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider).valueOrNull ?? true;
    final pending = ref.watch(appProvider.select((s) => s.pending.length));
    if (online) return const SizedBox.shrink();
    return Material(
      color: SB.warning,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(children: [
            const Icon(Icons.cloud_off, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('You are offline. Saved data still works. $pending change(s) are stored on this device only.', style: const TextStyle(color: Colors.white, fontSize: 12.5))),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback helpers
// ---------------------------------------------------------------------------

void showToast(BuildContext context, String message) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String message, String confirmLabel = 'Confirm', bool destructive = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel, style: TextStyle(color: destructive ? SB.error : SB.accent, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ---------------------------------------------------------------------------
// Domain cards
// ---------------------------------------------------------------------------

const _tradePalette = [Color(0xFFB5593A), Color(0xFFC98A2B), Color(0xFF5F8A6B), Color(0xFF3F7C99), Color(0xFF8A5A83), Color(0xFF8C7A3A)];

/// A stable earthy colour for each trade, so categories are easy to tell apart.
Color tradeColor(String id) {
  final i = kTrades.indexWhere((t) => t.id == id);
  return _tradePalette[(i < 0 ? 0 : i) % _tradePalette.length];
}

/// Category tile: a rounded picture with the trade name underneath.
class TradeCard extends StatelessWidget {
  const TradeCard(this.trade, {super.key, required this.onTap, this.compact = false});
  final TradeCategory trade;
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Browse ${trade.name}',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(aspectRatio: compact ? 1 : 1.3, child: TradeImage(trade.id)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
              child: Text(trade.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
          ]),
        ),
      );
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(20)),
        child: child,
      );
}

/// Circular white button used over photos.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.color});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .95),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(message: tooltip, child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 21, color: color ?? SB.text))),
        ),
      );
}

class WorkerCard extends ConsumerWidget {
  const WorkerCard(this.w, {super.key, this.compact = false});
  final WorkerProfile w;
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(appProvider);
    final r = st.ratingFor(w);
    final trade = tradeById(w.tradeId);
    final fav = st.favourites.contains(w.id);
    final own = st.isWorker && st.myWorkerId == w.id;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/worker/${w.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(height: compact ? 150 : 190, width: double.infinity, child: WorkerPhoto(w)),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: _Glass(child: Text(w.isAvailable ? 'Available' : 'Busy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: w.isAvailable ? SB.success : SB.warning))),
          ),
          if (!own)
            Positioned(
              right: 10,
              top: 10,
              child: RoundIconButton(
                icon: fav ? Icons.favorite : Icons.favorite_border,
                color: fav ? SB.error : null,
                tooltip: fav ? 'Remove from favourites' : 'Save to favourites',
                onTap: () => ref.read(appProvider.notifier).toggleFavourite(w.id),
              ),
            ),
          Positioned(left: 10, bottom: 10, child: _Glass(child: RatingRow(average: r.average, count: r.count, size: 14))),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700))),
          if (w.startingPrice != null) Text('From ${zmw(w.startingPrice!)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: SB.accent)),
        ]),
        const SizedBox(height: 2),
        Text('${trade.name} · ${w.location}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SB.text2, fontSize: 13)),
        const SizedBox(height: 6),
        VerificationChip(w),
      ]),
    );
  }
}

/// Labelled section used by forms: a title followed by its children.
class FormSection extends StatelessWidget {
  const FormSection(this.title, {super.key, required this.children, this.hint});
  final String title;
  final String? hint;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SB.text)),
        ),
        if (hint != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(hint!, style: const TextStyle(fontSize: 12.5, color: SB.text2))),
        ...children,
      ]);
}

class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Icons.info_outline, this.color = SB.accent});
  final String text;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.4))),
        ]),
      );
}

/// Horizontal list of choice chips that can be cleared by tapping the selected one.
class ChipGroup<T> extends StatelessWidget {
  const ChipGroup({super.key, required this.options, required this.selected, required this.label, required this.onSelected});
  final List<T> options;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T?> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 4, children: [
        for (final o in options)
          ChoiceChip(
            label: Text(label(o)),
            selected: selected == o,
            showCheckmark: false,
            labelStyle: TextStyle(fontSize: 13, color: selected == o ? Colors.white : SB.text),
            onSelected: (v) => onSelected(v ? o : null),
          ),
      ]);
}

Future<DateTime?> pickDate(BuildContext context, {DateTime? initial, bool future = true}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: future ? DateTime(now.year, now.month, now.day) : DateTime(now.year - 30),
    lastDate: future ? DateTime(now.year + 3) : now,
  );
}


// ---------------------------------------------------------------------------
// Decoration and motion
// ---------------------------------------------------------------------------

/// Plain navy panel. Kept as a soft gradient so screens stay clean.
class ArchBackdrop extends StatelessWidget {
  const ArchBackdrop({super.key, required this.child, this.colors = const [SB.navy, SB.navyLight], this.radius = 26, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final List<Color> colors;
  final double radius;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors)),
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// Fades and lifts its child into place. Give list items an [index] to stagger them.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 360 + 70 * (index > 8 ? 8 : index)),
        curve: Curves.easeOutCubic,
        builder: (c, v, ch) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: ch)),
        child: child,
      );
}


// ---------------------------------------------------------------------------
// Photos and list cards
// ---------------------------------------------------------------------------

/// Asset photo with a trade picture as fallback if the file is missing.
class AppPhoto extends StatelessWidget {
  const AppPhoto(this.path, {super.key, required this.fallbackTradeId, this.fit = BoxFit.cover});
  final String path;
  final String fallbackTradeId;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Image.asset(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => TradeImage(fallbackTradeId, fit: fit),
      );
}

/// Worker photo: their own picked photo, else assets/people/worker_01..12.jpg
/// (chosen by the worker's trade), else the trade picture.
class WorkerPhoto extends StatelessWidget {
  const WorkerPhoto(this.w, {super.key});
  final WorkerProfile w;
  @override
  Widget build(BuildContext context) {
    final fallback = TradeImage(w.tradeId);
    if (w.photoPath != null) {
      return Image.file(File(w.photoPath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, _, _) => fallback);
    }
    final i = kTrades.indexWhere((t) => t.id == w.tradeId);
    final n = (i < 0 ? 0 : i % 12) + 1;
    return AppPhoto('assets/people/worker_${n.toString().padLeft(2, '0')}.jpg', fallbackTradeId: w.tradeId);
  }
}

/// Horizontal photo card for lists: Browse results, Favourites, dashboards.
class WorkerRowCard extends ConsumerWidget {
  const WorkerRowCard(this.w, {super.key, this.trailing});
  final WorkerProfile w;
  final Widget? trailing;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(appProvider);
    final r = st.ratingFor(w);
    final trade = tradeById(w.tradeId);
    final fav = st.favourites.contains(w.id);
    return SbCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/worker/${w.id}'),
      child: SizedBox(
        height: 136,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(SB.radius)),
            child: SizedBox(width: 104, child: WorkerPhoto(w)),
          ),
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 48, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${trade.name} · ${w.location}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SB.text2, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    RatingRow(average: r.average, count: r.count, size: 13),
                    const SizedBox(height: 8),
                    Row(children: [
                      StatusPill(w.isAvailable ? 'Available' : 'Busy', color: w.isAvailable ? SB.success : SB.warning),
                      const SizedBox(width: 8),
                      if (w.startingPrice != null) Flexible(child: Text('From ${zmw(w.startingPrice!)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SB.accent))),
                    ]),
                  ]),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: trailing ??
                    IconButton(
                      tooltip: fav ? 'Remove from favourites' : 'Save to favourites',
                      icon: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 22, color: fav ? SB.error : SB.text2),
                      onPressed: () => ref.read(appProvider.notifier).toggleFavourite(w.id),
                    ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Messages list row. Shows the other person, last message and unread count.
class ConversationTile extends ConsumerWidget {
  const ConversationTile(this.c, {super.key});
  final Conversation c;

  String _when(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Now';
    if (d.inHours < 1) return '${d.inMinutes} min';
    if (d.inDays < 1) return '${d.inHours} h';
    if (d.inDays < 7) return '${d.inDays} d';
    return '${t.day}/${t.month}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(appProvider);
    final worker = st.worker(c.workerId);
    final name = st.isWorker ? c.clientName : (worker?.name ?? 'Worker');
    final unread = st.unreadFor(c);
    final last = c.last;
    return SbCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => context.push('/chat/${c.id}'),
      child: Row(children: [
        if (!st.isWorker && worker != null)
          ClipOval(child: SizedBox(width: 54, height: 54, child: WorkerPhoto(worker)))
        else
          Avatar(name: name, size: 54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w700))),
              if (last != null) Text(_when(last.at), style: TextStyle(fontSize: 12, color: unread > 0 ? SB.terracotta : SB.text2)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Expanded(
                child: Text(last?.text ?? 'Say hello', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: unread > 0 ? SB.text : SB.text2, fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400)),
              ),
              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: SB.terracotta, borderRadius: BorderRadius.circular(10)),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
