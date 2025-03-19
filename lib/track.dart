import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:music_player/AuthorPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackPage extends StatefulWidget {
  final int trackId;

  const TrackPage({
    super.key,
    required this.trackId,
  });

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  bool isPlaying = false;
  late final AudioPlayer audioPlayer;
  Duration _duration = Duration();
  Duration _position = Duration();

  Map<String, dynamic>? _trackData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _fetchTrackData();
  }

  Future<void> _fetchTrackData() async {
    try {
      final response = await Supabase.instance.client
          .from('Track')
          .select("*, Author(Name)")
          .eq('id', widget.trackId)
          .single();

      setState(() {
        _trackData = response;
        _isLoading = false;
      });

      initPlayer();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> initPlayer() async {
    if (_trackData != null) {
      await audioPlayer.setSource(UrlSource(_trackData!['MusicUrl']));

      audioPlayer.onDurationChanged.listen((duration) {
        setState(() {
          _duration = duration;
        });
      });

      audioPlayer.onPositionChanged.listen((position) {
        setState(() {
          _position = position;
        });
      });

      audioPlayer.onPlayerComplete.listen((completed) async {
        setState(() {
          _position = _duration;
          isPlaying = false;
        });

        final int? nextTrackId = await _getNextTrackId();
        if (nextTrackId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TrackPage(trackId: nextTrackId),
            ),
          );
        }
      });
      await audioPlayer.play(audioPlayer.source!);
      isPlaying = true;
    }
  }

  Future<int?> _getNextTrackId() async {
    try {
      final response = await Supabase.instance.client
          .from('Track')
          .select('id')
          .order('id', ascending: false)
          .limit(1)
          .single();

      final int maxTrackId = response['id'];

      if (widget.trackId >= maxTrackId) {
        return 1;
      }

      return widget.trackId + 1;
    } catch (e) {
      print('Error fetching next track ID: $e');
      return null;
    }
  }

  void playPause() async {
    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play(UrlSource(_trackData!['MusicUrl']));
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void rewind() async {
    if (_duration.inSeconds > 0) {
      final newPosition = Duration(seconds: _position.inSeconds - 10);
      await audioPlayer.seek(newPosition);
      setState(() {
        _position = newPosition;
      });
    }
  }

  void fastForward() async {
    if (_duration.inSeconds > 0) {
      final newPosition = Duration(seconds: _position.inSeconds + 10);
      await audioPlayer.seek(newPosition);
      setState(() {
        _position = newPosition;
      });
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_trackData == null) {
      return Scaffold(
        body: Center(
          child: Text('Failed to load track data'),
        ),
      );
    }

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
          appBar: AppBar(
            title: Center(child: Text(_trackData!['Name'], style: TextStyle(color: Colors.white),)),
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
          leading: IconButton(onPressed: () {Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
            actions: [Padding(padding: EdgeInsets.all(8.0), child: IconButton(icon: Icon(Icons.person), onPressed: () {}, style: ButtonStyle(iconColor: WidgetStateColor.transparent), hoverColor: WidgetStateColor.transparent,))],
            ),
          //),
          body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                _trackData!['Image'],
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width * 0.6,
              ),
            ),
            ListTile(
              textColor: Colors.white,
              title: Text(
                _trackData!['Name'],
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: TextButton(
                child: Text(
                  _trackData!['Author']['Name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => AuthorPage(authorId: _trackData!['Id_Author']),
            ),),
                
              ),
            ),
            Slider(
              min: 0,
              max: _duration.inSeconds.toDouble(),
              activeColor: Colors.blue,
              inactiveColor: Colors.white,
              value: _position.inSeconds.toDouble(),
              onChanged: (value) async {
                await audioPlayer.seek(Duration(seconds: value.toInt()));
                setState(() {});
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _position.format(_position),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(" / ", style: TextStyle(color: Colors.white)),
                Text(
                  _duration.format(_duration),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.05),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  color: Colors.white,
                  onPressed: _duration.inSeconds > 0 ? rewind : null,
                  icon: SizedBox(child: Icon(Icons.fast_rewind, size: 60)),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: playPause,
                  icon: isPlaying
                      ? Icon(Icons.pause_circle, size: 60)
                      : Icon(Icons.play_circle, size: 60),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: _duration.inSeconds > 0 ? fastForward : null,
                  icon: Icon(Icons.fast_forward, size: 60),
                ),
              ],
            ),
          ],
        ),
        )
      );
  }
}

extension on Duration {
  String format(Duration duration) {
    String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}