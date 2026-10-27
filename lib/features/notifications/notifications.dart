import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../../state/app_state.dart';
import '../home/home_screens.dart' show notifIcon;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final items = s.myNotifications;
    final ctl = ref.read(appProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text('Notifications${s.unreadNotifications > 0 ? ' (${s.unreadNotifications})' : ''}'), actions: [if (s.unreadNotifications > 0) TextButton(onPressed: ctl.markAllRead, child: const Text('Mark all read'))]),
      body: items.isEmpty
          ? const EmptyState(icon: Icons.notifications_none, title: 'All caught up', message: 'Job matches, applications, bookings and reminders will appear here.')
          : ListView.separated(
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                if (i == items.length) return const Padding(padding: EdgeInsets.all(SB.pad), child: Text('These are in-app notifications saved on this device. Push notifications from a server are not part of this prototype.', style: TextStyle(fontSize: 12, color: SB.text2)));
                final n = items[i];
                return ListTile(
                  tileColor: n.read ? null : const Color(0x0F4C7FA8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: SB.pad, vertical: 4),
                  leading: CircleAvatar(backgroundColor: SB.soft, child: Icon(notifIcon(n.type), color: SB.navy, size: 20)),
                  title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w800)),
                  subtitle: Text(n.body),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(timeAgo(n.at), style: const TextStyle(fontSize: 11.5, color: SB.text2)),
                    if (!n.read) const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.circle, size: 9, color: SB.accent, semanticLabel: 'Unread')),
                  ]),
                  onTap: () {
                    ctl.markNotificationRead(n.id);
                    if (n.route != null) context.push(n.route!);
                  },
                );
              },
            ),
    );
  }
}
