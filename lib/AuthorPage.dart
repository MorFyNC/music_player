import 'package:flutter/material.dart';
import 'package:music_player/track.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'TrackList.dart';

class AuthorPage extends StatefulWidget {
  final int authorId;

  const AuthorPage({super.key, required this.authorId});

  @override
  State<AuthorPage> createState() => _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  final supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _artistFuture;
  late Future<List<Map<String, dynamic>>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _artistFuture = _fetchArtist();
    _tracksFuture = _fetchTracks();
  }

  Future<Map<String, dynamic>> _fetchArtist() async {
    final response = await supabase
        .from('Author')
        .select()
        .eq('id', widget.authorId)
        .single();

    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchTracks() async {
    final response = await supabase
        .from('Track')
        .select('*, Author (Name, Image)')
        .eq('Id_Author', widget.authorId);

    return response;
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
          title: Center(child: Text('Исполнитель', style: TextStyle(color: Colors.white),)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(onPressed: () {Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
          actions: [Padding(padding: EdgeInsets.all(8.0), child: IconButton(icon: Icon(Icons.person), onPressed: () {}, style: ButtonStyle(iconColor: WidgetStateColor.transparent), hoverColor: WidgetStateColor.transparent,))],
        ),
        body: FutureBuilder(
          future: Future.wait([_artistFuture, _tracksFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка загрузки данных'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('Нет данных'));
            }

            final artist = snapshot.data![0] as Map<String, dynamic>;
            final tracks = snapshot.data![1] as List<Map<String, dynamic>>;

            return SizedBox(
              width: double.infinity, // Занимает всю ширину
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Центрирование по вертикали
                crossAxisAlignment: CrossAxisAlignment.center, // Центрирование по горизонтали
                children: [
                  const SizedBox(height: 16), // Отступ сверху
                  CircleAvatar(
                    backgroundImage: NetworkImage(artist['Image']),
                    radius: 60,
                  ),
                  const SizedBox(height: 16), // Отступ между аватаркой и текстом
                  Text(
                    artist['Name'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24), // Отступ между текстом и списком треков
                  Expanded(
                    child: TrackList(tracks: tracks, onTrackSelected: (trackId) {Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackPage(trackId: trackId),
              ),
            );},),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}