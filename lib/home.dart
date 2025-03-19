import 'package:flutter/material.dart';
import 'package:music_player/AuthorPage.dart';
import 'package:music_player/HorizontalButtonList.dart';
import 'package:music_player/PlaylistPage.dart';
import 'package:music_player/SectionHeader.dart';
import 'package:music_player/TrackList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ProfilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTracks() async {
    try {
      final response = await supabase
          .from('Track')
          .select('*, Author (Name)')
          .then((response) => response);

      return response;
    } catch (e) {
      throw Exception('Error fetching tracks: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId')!;
      final response = await supabase
          .from('Playlist')
          .select('*')
          .eq('Id_user', userId)
          .then((response) => response);

      return response;
    } catch (e) {
      throw Exception('Error fetching playlists: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getArtists() async {
    try {
      final response = await supabase
          .from('Author')
          .select('*')
          .then((response) => response);

      return response;
    } catch (e) {
      throw Exception('Error fetching artists: $e');
    }
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
          
          title: Center(child: Text('Music App', style: TextStyle(color: Colors.white))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(padding: EdgeInsets.all(8.0), child: IconButton(icon: Icon(Icons.person), onPressed: () {}, style: ButtonStyle(iconColor: WidgetStateColor.transparent), hoverColor: WidgetStateColor.transparent,)),
          actions: [
            Padding(padding: EdgeInsets.all(8),child: IconButton(
              icon: Icon(Icons.person, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
        )],
        ),
        body: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            SectionHeader(title: 'Ваши плейлисты'),
            HorizontalButtonList(
              itemsFuture: getPlaylists(),
              onPressed: (item) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistPage(playlistId: item['id']),
                  ),
                );
              },
            ),
            SectionHeader(title: 'Популярные исполнители'),
            HorizontalButtonList(
              itemsFuture: getArtists(),
              onPressed: (item) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuthorPage(authorId: item['id']),
                  ),
                );
              },
            ),
            SectionHeader(title: 'Треки'),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: getTracks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка загрузки данных'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Нет данных'));
                } else {
                  final tracks = snapshot.data!;
                  return TrackList(tracks: tracks);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}