import 'package:flutter/material.dart';
import 'package:smart_collab/widgets/add_team_sheet.dart';

class AddTeamButton extends StatelessWidget {
  const AddTeamButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // open bottom sheet to add team
        showModalBottomSheet(
          isScrollControlled: true,
          // show handle
          enableDrag: true,
          showDragHandle: true,
          context: context,
          builder: (context) => Padding(
            padding: MediaQuery.of(context)
                .viewInsets
                .copyWith(left: 16, right: 16),
            child: const AddTeamSheet(),
          ),
        );
      },
      child: const Text('Add Team'),
    );
  }
}
