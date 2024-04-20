import 'package:flutter/material.dart';

class IssueTabs extends StatefulWidget {
  final Function(int) onTabChange;
  const IssueTabs({super.key, required this.onTabChange});

  @override
  State<IssueTabs> createState() => _IssueTabsState();
}

class _IssueTabsState extends State<IssueTabs> {
  int _currentTabIndex = 0;

  Widget _buildTab(int index, String label) {
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
          child: Text(
            label,
            style: TextStyle(
              color: _currentTabIndex == index ? Colors.blue : Colors.black,
              fontWeight: _currentTabIndex == index
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab(0, 'Open issues'),
          _buildTab(1, 'Upcoming'),
          _buildTab(2, 'Closed'),
        ],
      ),
    );
  }
}
