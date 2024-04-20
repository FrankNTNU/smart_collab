import 'package:flutter/material.dart';

class Tabs extends StatefulWidget {
  final Function(int) onTabChange;
  final List<String> tabs;
  final List<IconData>? icons;
  final int initialTabIndex;
  const Tabs({
    super.key,
    required this.onTabChange,
    this.icons,
    this.initialTabIndex = 0,
    this.tabs = const [
      'Open issues',
      'Upcoming',
      'Closed',
    ],
  });

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  int _currentTabIndex = 0;
  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
  }

  Widget _buildTab(int index, String label) {
    final canShowIcon = widget.icons != null &&
        widget.icons!.isNotEmpty &&
        widget.icons!.length == widget.tabs.length;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _currentTabIndex == index ? Colors.blue : Colors.white,
            width: 2,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
          widget.onTabChange(index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            children: [
              if (canShowIcon)
                Icon(
                  widget.icons![index],
                  color: _currentTabIndex == index
                      ? Colors.blue
                      : null
                ),
              if (canShowIcon)
                const SizedBox(
                  width: 8,
                ),
              Text(
                label,
                style: TextStyle(
                  color: _currentTabIndex == index
                      ? Colors.blue
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: _currentTabIndex == index
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              _buildTab(i, widget.tabs[i]),
          ],
        ),
      ),
    );
  }
}
