import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/screens/calendar_view.dart';
import 'package:smart_collab/screens/teams_drawer.dart';
import 'package:smart_collab/services/activity_controller.dart';
import 'package:smart_collab/services/auth_controller.dart';
import 'package:smart_collab/utils/translation_keys.dart';
import 'package:smart_collab/widgets/cover_image.dart';
import 'package:smart_collab/widgets/notification_bell.dart';
import 'package:smart_collab/widgets/profile_greeting_tile.dart';
import 'package:smart_collab/widgets/team_info.dart';

import '../services/issue_controller.dart';
import '../services/team_controller.dart';
import '../widgets/issues.dart';
import '../widgets/tab_view_bar.dart';

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
  bool _isIssueTabsVisible = true;
  int _currentTabIndex = 0;

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
    final uid =
        ref.watch(authControllerProvider.select((value) => value.user?.uid));
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    icon: _mainFeatureTabIndex == 0
                        ? const Icon(Icons.home)
                        : const Icon(Icons.home_outlined),
                    label: TranslationKeys.home.tr(),
                  ),
                  BottomNavigationBarItem(
                    icon: _mainFeatureTabIndex == 1
                        ? const Icon(Icons.event)
                        : const Icon(Icons.event_outlined),
                    label: TranslationKeys.calendar.tr(),
                  ),
                  BottomNavigationBarItem(
                    icon: _mainFeatureTabIndex == 2
                        ? const Icon(Icons.group)
                        : const Icon(Icons.group_outlined),
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
            : Stack(
                children: [
                  RefreshIndicator(
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
                        const ProfileGreetingTile(), // show cover image
                        if (teamData.imageUrl != null)
                          // network image
                          CoverImage(
                            imageUrl: teamData.imageUrl!,
                            isRoundedBorder: false,
                            // height: _coverImageHeight,
                          ),
                        // tabs
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
                        // calendar
                        if (_mainFeatureTabIndex ==
                            MainFeatureTabIndex.calendar)
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
                        // team info
                        if (_mainFeatureTabIndex == MainFeatureTabIndex.about)
                          TeamInfo(team: teamData),
                        // issues
                        if (_mainFeatureTabIndex == MainFeatureTabIndex.home)
                          Issues(
                            currentTabIndex: _currentTabIndex,
                            teamId: teamData.id!,
                            isTabsVisibleOnChanged: (visible) {
                              setState(() {
                                _isIssueTabsVisible = visible;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  // position top
                  if (!_isIssueTabsVisible &&
                      _mainFeatureTabIndex == MainFeatureTabIndex.home)
                    _isIssueTabsVisible
                        ? const SizedBox.shrink()
                        : Positioned(
                            top: 0,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Tabs(
                                initialTabIndex: _currentTabIndex,
                                onTabChange: (index) {
                                  setState(() {
                                    _currentTabIndex = index;
                                  });
                                },
                                tabs: [
                                  TranslationKeys.openIssues.tr(),
                                  TranslationKeys.upcoming.tr(),
                                  TranslationKeys.overdue.tr(),
                                  TranslationKeys.closedIssues.tr(),
                                ],
                                icons: const [
                                  Icons.content_paste,
                                  Icons.hourglass_top_rounded,
                                  Icons.event_busy,
                                  Icons.check
                                ],
                              ),
                            ),
                          ),
                ],
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
