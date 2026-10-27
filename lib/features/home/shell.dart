import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// Clean, shared bottom navigation for worker and client roles.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appProvider.select((s) => s.role));
    final unread = ref.watch(appProvider.select((s) => s.unreadMessages));
    final worker = role == UserRole.worker;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home', 0),
      worker
          ? (Icons.search_outlined, Icons.search_rounded, 'Find Jobs', 0)
          : (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Browse', 0),
      worker
          ? (Icons.work_outline_rounded, Icons.work_rounded, 'My Work', 0)
          : (Icons.add_box_outlined, Icons.add_box_rounded, 'Post Job', 0),
      (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Messages', unread),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 0),
    ];

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9EDF2))),
          ),
          padding: const EdgeInsets.fromLTRB(4, 7, 4, 4),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == shell.currentIndex,
                    label: items[i].$3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => shell.goBranch(
                        i,
                        initialLocation: i == shell.currentIndex,
                      ),
                      child: SizedBox(
                        height: 56,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Badge(
                              label: Text('${items[i].$4}'),
                              isLabelVisible: items[i].$4 > 0,
                              child: Icon(
                                i == shell.currentIndex ? items[i].$2 : items[i].$1,
                                size: 23,
                                color: i == shell.currentIndex
                                    ? SB.navy
                                    : SB.text2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items[i].$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 1.1,
                                fontWeight: i == shell.currentIndex
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == shell.currentIndex
                                    ? SB.navy
                                    : SB.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
