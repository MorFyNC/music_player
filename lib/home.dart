import 'package:flutter/material.dart';
import 'package:music_player/AuthorPage.dart';
import 'package:music_player/HorizontalButtonList.dart';
import 'package:music_player/PlaylistPage.dart';
import 'package:music_player/SectionHeader.dart';
import 'package:music_player/TrackList.dart';
import 'package:music_player/bottom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ProfilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  int _currentTrackId = 1;
  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _artists = [];
  final GlobalKey<BottomPlayerState> _bottomPlayerKey = GlobalKey();
  bool _isLoading = false;
  bool _isTrackLoading = false; // Новое состояние для загрузки трека

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final [tracks, playlists, artists] = await Future.wait([
        _fetchTracks(),
        _fetchPlaylists(),
        _fetchArtists(),
      ]);

      setState(() {
        _tracks = tracks;
        _playlists = playlists;
        _artists = artists;
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTracks() async {
    final response = await supabase
        .from('Track')
        .select('*, Author (Name)');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return [];
    
    final response = await supabase
        .from('Playlist')
        .select('*')
        .eq('Id_user', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchArtists() async {
    final response = await supabase.from('Author').select('*');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _playNextTrack() async {
    if (_tracks.isEmpty) return;
    final currentIndex = _tracks.indexWhere((t) => t['id'] == _currentTrackId);
    final newTrackId = (currentIndex == -1 || currentIndex == _tracks.length - 1)
        ? _tracks.first['id']
        : _tracks[currentIndex + 1]['id'];
    await _updateTrack(newTrackId);
  }

  Future<void> _playPreviousTrack() async {
    if (_tracks.isEmpty) return;
    final currentIndex = _tracks.indexWhere((t) => t['id'] == _currentTrackId);
    final newTrackId = (currentIndex == -1 || currentIndex == 0)
        ? _tracks.last['id']
        : _tracks[currentIndex - 1]['id'];
    await _updateTrack(newTrackId);
  }

  Future<void> _updateTrack(int trackId) async {
    if (_currentTrackId == trackId) return;
    
    setState(() {
      _isTrackLoading = true; // Показываем загрузку
      _currentTrackId = trackId;
    });

    try {
      await _bottomPlayerKey.currentState?.updateTrack(trackId);
    } finally {
      if (mounted) {
        setState(() {
          _isTrackLoading = false; // Скрываем загрузку
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blueGrey],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Music App', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage()),
              ),
            )
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: 180,
          child: Stack(
  children: [
    BottomPlayer(key: _bottomPlayerKey,
                initialTrackId: _currentTrackId,
                onNext: _playNextTrack,
                onPrevious: _playPreviousTrack,),
    if (_isTrackLoading)
      Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
  ],
)
        ),
        body: _isLoading && _tracks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadInitialData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SectionHeader(title: 'Ваши плейлисты'),
                    HorizontalButtonList(
                      itemsFuture: Future.value(_playlists),
                      onPressed: (item) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistPage(playlistId: item['id']),
                        ),
                      ),
                    ),
                    SectionHeader(title: 'Популярные исполнители'),
                    HorizontalButtonList(
                      itemsFuture: Future.value(_artists),
                      onPressed: (item) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthorPage(authorId: item['id']),
                        ),
                      ),
                    ),
                    SectionHeader(title: 'Треки'),
                    _tracks.isEmpty
                        ? const Center(child: Text('Нет треков'))
                        : TrackList(
                            tracks: _tracks,
                            onTrackSelected: _updateTrack,
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}