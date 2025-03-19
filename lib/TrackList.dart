import 'package:flutter/material.dart';
import 'package:music_player/track.dart';

class TrackList extends StatelessWidget {
  final List<Map<String, dynamic>> tracks;

  const TrackList({super.key, required this.tracks});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final authorName = track['Author']?['Name'] ?? 'Unknown Artist';
        return ListTile(
          title: Text(
            track['Name'],
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            authorName,
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackPage(trackId: track['id']),
              ),
            );
          },
        );
      },
    );
  }
}