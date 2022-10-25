import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;

final Uri url = Uri.parse("https://itsallwidgets.com/podcast/feed");

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'The Boring Show',
      home: EpisodesPage(),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  const EpisodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: http.get(url),
        builder: (BuildContext context, AsyncSnapshot<http.Response> snapshot) {
          if (snapshot.hasData) {
            final response = snapshot.data;
            if (response?.statusCode == 200) {
              final rssString = response?.body;
              var rssFeed = RssFeed.parse(rssString!);
              return EpisodeListView(rssFeed: rssFeed);
            }
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
    Key? key,
    required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed.items!
          .map(
            (i) => ListTile(
              title: Text(i.title!),
              subtitle: Text(
                i.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => PlayerPage(item: i)),
                ));
              },
            ),
          )
          .toList(),
    );
  }
}

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key, required this.item});
  final RssItem item;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Admiral AppBar'),
        ),
        body: const SafeArea(
          child: Player(),
        ) //Center(child: PlaybackButton()),
        );
  }
}

class Player extends StatelessWidget {
  const Player({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const <Widget>[
        Flexible(
          flex: 9,
          child: Placeholder(),
        ),
        Flexible(flex: 2, child: AudioControls()),
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaybackButton();
  }
}

class PlaybackButton extends StatefulWidget {
  const PlaybackButton({super.key});

  @override
  State<PlaybackButton> createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends State<PlaybackButton> {
  bool _isPlaying = false;
  final FlutterSoundPlayer _myPlayer = FlutterSoundPlayer();
  bool _myPlayerInit = false;

  double _playPosition = 0.0;

  StreamSubscription<PlaybackDisposition>? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _myPlayer.openPlayer().then(
          (value) => setState(
            () {
              _myPlayerInit = true;
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Slider(
          value: _playPosition,
          onChanged: (double value) {},
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.fast_rewind),
              onPressed: backward,
            ),
            IconButton(
              icon: _isPlaying
                  ? const Icon(Icons.stop)
                  : const Icon(Icons.play_arrow),
              onPressed: () {
                if (_isPlaying) {
                  _stop();
                } else {
                  _play();
                }
              },
            ),
            IconButton(
              onPressed: forward,
              icon: const Icon(Icons.fast_forward),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _myPlayer.closePlayer();
    _playerSubscription!.cancel();
    super.dispose();
  }

  void _stop() {
    _myPlayer.pausePlayer();
    setState(() => _isPlaying = false);
  }

  void _play() async {
    if (_myPlayerInit && _myPlayer.isPaused) {
      _myPlayer.resumePlayer();
    } else {
      const url =
          'https://cdn.pixabay.com/download/audio/2022/10/12/audio_061cead49a.mp3?filename=weeknds-122592.mp3';
      Duration? d = await _myPlayer.startPlayer(fromURI: url);
      _myPlayer.setSubscriptionDuration(const Duration(milliseconds: 1000));

      _playerSubscription = _myPlayer.onProgress!.listen((event) {
        // print(event.duration.inSeconds - event.position.inSeconds);
        setState(() => _playPosition = event.position.inSeconds / d!.inSeconds);
      });
      setState(() => _isPlaying = true);
    }
  }

  backward() {}

  forward() {}
}

class PlaybackButtons extends StatelessWidget {
  const PlaybackButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: PlaybackButton(),
    );
  }
}
