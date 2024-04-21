import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/activity_screen.dart';
import 'package:smart_collab/services/activity_controller.dart';

class NotificationBell extends ConsumerStatefulWidget {
  final String teamId;
  const NotificationBell({super.key, required this.teamId}) ;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final unreadActivities = ref.watch(
      activityProvider(widget.teamId).select(
          (value) => value.activities.where((activity) => !activity.read)),
    );
    // get the acitivity count where teamId is equal to widget.teamId. { teamId: "teamId "}
    final activityCount = unreadActivities.length;

    return IconButton(
        onPressed: () {
          // show bottom sheet
          showModalBottomSheet(
            isScrollControlled: true,
            enableDrag: true,
            showDragHandle: true,
            context: context,
            builder: (context) {
              return ActivityScreen(
                teamId: widget.teamId,
              );
            },
          );
        },
        icon: activityCount > 0
            ? Badge(
                label: Text('$activityCount'),
                child: const Icon(
                  Icons.notifications_outlined,
                ),
              )
            : const Icon(
                Icons.notifications_outlined,
              ));
  }
}
