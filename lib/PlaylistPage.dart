import 'package:flutter/material.dart';
import 'package:music_player/track.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'TrackList.dart';

class PlaylistPage extends StatefulWidget {
  final int playlistId;

  const PlaylistPage({super.key, required this.playlistId});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _playlistFuture;
  late Future<List<Map<String, dynamic>>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _playlistFuture = _fetchPlaylist();
    _tracksFuture = _fetchTracks();
  }

  Future<Map<String, dynamic>> _fetchPlaylist() async {
    final response = await supabase
        .from('Playlist')
        .select()
        .eq('id', widget.playlistId)
        .single();

    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchTracks() async {
    final trackIdsResponse = await supabase
        .from('Playlist_track')
        .select('Id_track')
        .eq('Id_playlist', widget.playlistId);

    final trackIds = trackIdsResponse.map((item) => item['Id_track']).toList();

    final tracksResponse = await supabase
        .from('Track')
        .select('*, Author (Name)')
        .inFilter('id', trackIds);

    return tracksResponse;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Center(child: Text('Плейлист', style: TextStyle( color: Colors.white ),),),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(onPressed: () {Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
          actions: [Padding(padding: EdgeInsets.all(8.0), child: IconButton(icon: Icon(Icons.person), onPressed: () {}, style: ButtonStyle(iconColor: WidgetStateColor.transparent), hoverColor: WidgetStateColor.transparent,))],
        ),
        body: FutureBuilder(
          future: Future.wait([_playlistFuture, _tracksFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка загрузки данных'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('Нет данных'));
            }

            final playlist = snapshot.data![0] as Map<String, dynamic>;
            final tracks = snapshot.data![1] as List<Map<String, dynamic>>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    playlist['Name'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: TrackList(tracks: tracks, onTrackSelected: (trackId) {Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackPage(trackId: trackId),
              ),
            );},),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}