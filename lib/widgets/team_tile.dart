import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/team_screen.dart';
import '../services/team_controller.dart';
import 'cover_image.dart';

class TeamTile extends ConsumerStatefulWidget {
  const TeamTile({super.key, required this.team});
  final Team team;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TeamTileState();
}

class _TeamTileState extends ConsumerState<TeamTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return TeamScreen(
                team: widget.team,
              );
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // bottom border
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            // large image
            if (widget.team.imageUrl?.isNotEmpty == true)
              CoverImage(
                imageUrl: widget.team.imageUrl!,
              )
            else
              Container(
                height: 128,
                width: double.infinity,
                // border radius
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image),
              ),
            ListTile(
              contentPadding: const EdgeInsets.all(0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.team.name ?? ''),
                  Wrap(children: [const Icon(
                    Icons.group,
                  ),
                  const SizedBox(width: 8),
                  // member count
                  Text(
                    '${widget.team.roles.length}',
                    style: const TextStyle(
                    ),
                  ),],)
                ],
              ),
              subtitle: Text(widget.team.description ?? '',
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
