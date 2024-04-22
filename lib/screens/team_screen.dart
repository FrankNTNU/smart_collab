import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/calendar_view.dart';
import 'package:smart_collab/screens/teams_drawer.dart';
import 'package:smart_collab/services/activity_controller.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/utils/translation_keys.dart';
import 'package:smart_collab/widgets/add_or_edit_team_sheet.dart';
import 'package:smart_collab/widgets/cover_image.dart';
import 'package:smart_collab/widgets/delete_confirm_dialog.dart';
import 'package:smart_collab/widgets/invite_to_team.dart';
import 'package:smart_collab/widgets/notification_bell.dart';
import 'package:smart_collab/widgets/stats.dart';
import 'package:smart_collab/widgets/team_members.dart';

import '../services/issue_controller.dart';
import '../services/team_controller.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/issues.dart';
import '../widgets/tab_view_bar.dart';
import '../widgets/title_text.dart';
import '../widgets/user_avatar.dart';

class MainFeatureTabIndex {
  static const int home = 0;
  static const int calendar = 1;
  static const int about = 2;
  static const int activities = 3;
}

class TeamScreen extends ConsumerStatefulWidget {
  final Team? team;
  final Function(Team team)? onTeamSelected;
  final Function(bool) toggleTheme;
  final bool isDarkMode;
  const TeamScreen(
      {super.key,
      required this.team,
      this.onTeamSelected,
      required this.toggleTheme,
      required this.isDarkMode});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  // scroll controller
  final _scrollController = ScrollController();
  // isCloseToBottom
  bool _isNotAtTop = false;
  // main feature tab index
  int _mainFeatureTabIndex = MainFeatureTabIndex.home;
  final bool _isDarkModel = false;

  void _logout() async {
    // confirm logout
    await showDialog(
      context: context,
      builder: (context) {
        return ConfirmDialog(
          title: TranslationKeys.logout.tr(),
          content: TranslationKeys.confirmSomething.tr(
            args: [TranslationKeys.logout.tr()],
          ),
          onConfirm: () {
            ref.read(authControllerProvider.notifier).signOut();
          },
          confirmText: TranslationKeys.logout.tr(),
        );
      },
    );
    // pop
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    // listen to scroll event
    _scrollController.addListener(() {
      bool isNotAtTop = _scrollController.position.pixels > 0;
      if (_isNotAtTop != isNotAtTop) {
        setState(() {
          _isNotAtTop = isNotAtTop;
        });
      }
      final isCloseToBottom = _scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent;
      if (isCloseToBottom && widget.team != null) {
        print('User reached end of list');
        ref
            .read(issueProvider(widget.team!.id!).notifier)
            .fetchIssues(widget.team!.id!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(authControllerProvider).user?.displayName;
    final teamData = ref.watch(teamsProvider.select((value) =>
        value.teams.where((team) => team.id == widget.team?.id).firstOrNull));
    final isLoading = ref.watch(
        teamsProvider.select((value) => value.apiStatus == ApiStatus.loading));
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    print('All roles: ${teamData?.roles}');
    final uid =
        ref.watch(authControllerProvider.select((value) => value.user?.uid));
    final isOwnerOrAdmin =
        teamData?.roles[uid] == 'owner' || teamData?.roles[uid] == 'admin';

    return _EagerInitialization(
      teamId: teamData?.id!,
      child: Scaffold(
        drawer: TeamsDrawer(
          onTeamSelected: widget.onTeamSelected,
          toggleTheme: widget.toggleTheme,
          isDarkMode: widget.isDarkMode,
        ),
        appBar: AppBar(
          title: Tooltip(
            message: 'teamId: ${teamData?.id}',
            child: Text(teamData?.name ?? ''),
          ),
          actions: [
            // notification icon button
            if (teamData != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: NotificationBell(
                  teamId: teamData.id!,
                ),
              ),
          ],
        ),
        bottomNavigationBar: kIsWeb
            ? null
            : BottomNavigationBar(
                currentIndex: _mainFeatureTabIndex,
                onTap: (value) => setState(() {
                  _mainFeatureTabIndex = value;
                }),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home),
                    label: TranslationKeys.home.tr(),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.event),
                    label: TranslationKeys.calendar.tr(),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.group),
                    label: TranslationKeys.about.tr(),
                  ),
                ],
              ),
        // scroll tp top button
        floatingActionButton: _isNotAtTop && // when the keybaord is not open
                MediaQuery.of(context).viewInsets.bottom == 0
            ? FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Icon(Icons.arrow_upward),
              )
            : null,
        body: teamData == null
            ? const Center(
                child: Text('Select a team from the left drawer'),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref
                      .read(issueProvider(widget.team!.id!).notifier)
                      .fetchIssues(widget.team!.id!);
                },
                child: ListView(
                  // make sure refresh indicator works
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TitleText(TranslationKeys.greeting
                                .tr(args: [username ?? 'User'])),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: UserAvatar(
                              uid: ref.watch(authControllerProvider).user!.uid!),
                        ),
                      ],
                    ),
                    // show cover image
                    if (teamData.imageUrl != null)
                      // network image
                      CoverImage(
                        imageUrl: teamData.imageUrl!,
                        isRoundedBorder: false,
                        // height: _coverImageHeight,
                      ),

                    if (kIsWeb)
                      Tabs(
                        initialTabIndex: _mainFeatureTabIndex,
                        tabs: [
                          TranslationKeys.home.tr(),
                          TranslationKeys.calendar.tr(),
                          TranslationKeys.about.tr(),
                          //TranslationKeys.activities.tr(),
                        ],
                        icons: const [
                          Icons.home,
                          Icons.event,
                          Icons.group,
                          //Icons.notifications,
                        ],
                        onTabChange: (index) {
                          setState(() {
                            _mainFeatureTabIndex = index;
                          });
                        },
                      ),

                    if (_mainFeatureTabIndex == MainFeatureTabIndex.calendar)
                      Column(
                        children: [
                          CalendarViewScreen(
                            teamId: widget.team!.id!,
                          ),
                          const SizedBox(
                            height: 32,
                          )
                        ],
                      ),
                    if (_mainFeatureTabIndex == MainFeatureTabIndex.about)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TitleText('${teamData.name}'),
                          ),
                          if (isOwnerOrAdmin)
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: Text(
                                        '${TranslationKeys.edit.tr()} ${TranslationKeys.team.tr()}'),
                                    onTap: () {
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        enableDrag: true,
                                        showDragHandle: true,
                                        context: context,
                                        builder: (context) {
                                          return AddTeamSheet(
                                            addOrEdit: AddorEdit.edit,
                                            team: teamData,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                PopupMenuItem(
                                  child: ListTile(
                                    leading: const Icon(Icons.delete),
                                    title: Text(TranslationKeys.delete.tr()),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return DeleteConfirmDialog(
                                            deleteValidationText: teamData
                                                    .name ??
                                                'I want to delete this team',
                                            title: 'Delete Team',
                                            content: TranslationKeys
                                                .confirmDeleteTeam
                                                .tr(),
                                            onConfirm: () {
                                              // have the user enter the team name before deletion

                                              ref
                                                  .read(teamsProvider.notifier)
                                                  .deleteTeam(teamData.id!);
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            },
                                            confirmText:
                                                TranslationKeys.delete.tr(),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                              icon: const Icon(Icons.more_horiz),
                            )
                        ],
                      ),
                    if (_mainFeatureTabIndex == MainFeatureTabIndex.about)
                      // description about team
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        child: Text(teamData.description ?? ''),
                      ),
                    if (_mainFeatureTabIndex == MainFeatureTabIndex.about)
                      const Divider(),
                    if (_mainFeatureTabIndex == MainFeatureTabIndex.about)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TitleText(
                              TranslationKeys.members.tr(),
                            ),
                          ),
                          if (isOwnerOrAdmin)
                            TextButton.icon(
                              label: Text(TranslationKeys.invite.tr()),
                              icon: const Icon(Icons.person_add),
                              onPressed: () {
                                showModalBottomSheet(
                                  isScrollControlled: true,
                                  enableDrag: true,
                                  showDragHandle: true,
                                  context: context,
                                  builder: (context) =>
                                      InviteToTeam(teamId: teamData.id!),
                                );
                              },
                            ),
                        ],
                      ),
                    if (_mainFeatureTabIndex == MainFeatureTabIndex.about)
                      // show a list of admins horizontally
                      TeamMembers(
                        teamId: teamData.id!,
                      ),
                    if (_mainFeatureTabIndex == MainFeatureTabIndex.about)
                      const Divider(),
                    if (_mainFeatureTabIndex == MainFeatureTabIndex.home)
                      Issues(teamId: teamData.id!),
                    if (_mainFeatureTabIndex == MainFeatureTabIndex.about)
                      StatsInfo(
                        teamId: teamData.id!,
                      )
                  ],
                ),
              ),
      ),
    );
  }
}

class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child, required this.teamId});
  final Widget child;
  final String? teamId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize providers by watching them.
    // By using "watch", the provider will stay alive and not be disposed.
    if (teamId != null) {
      ref.watch(activityStreamProvider(teamId!));
    }
    return child;
  }
}
