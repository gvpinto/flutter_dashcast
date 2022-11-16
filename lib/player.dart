import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dashcast/notifiers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.read<PodCast>().item!.title!),
      ),
      body: SafeArea(
        child: Player(),
      ), //Center(child: PlaybackButton()),
    );
  }
}

class Player extends StatelessWidget {
  final Logger log = Logger('Player');
  Player({super.key});

  @override
  Widget build(BuildContext context) {
    final podcast = context.read<PodCast>();
    return Column(
      children: [
        Flexible(
            flex: 8,
            child: SingleChildScrollView(
              child: Column(children: [
                Image.network(podcast.feed.image!.url!),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    podcast.item!.description!.trim(),
                  ),
                ),
              ]),
            )),
        const Flexible(
          flex: 2,
          child: Material(
            elevation: 12,
            child: AudioControls(),
          ),
        ),
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
  final log = Logger('PlaybackButton');
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
              log.fine('Initializing');
              _myPlayerInit = true;
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final item = context.read<PodCast>().item!;

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
              icon: !_isPlaying
                  ? const Icon(Icons.play_arrow)
                  : const Icon(Icons.stop),
              onPressed: () {
                if (_isPlaying) {
                  _stop();
                } else {
                  final url =
                      item.downloadPath != '' ? item.downloadPath : item.guid!;
                  log.fine('url: $url');
                  _play(url);
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
    _playerSubscription?.cancel();
    _myPlayerInit = false;
    super.dispose();
  }

  void _stop() async {
    await _myPlayer.pausePlayer();
    setState(() => _isPlaying = !_myPlayer.isPaused);
  }

  void _play(String url) async {
    if (_myPlayerInit && _isPlaying) {
      log.fine('Resume Player');
      await _myPlayer.resumePlayer();
      setState(() => _isPlaying = !_myPlayer.isPaused);
    } else {
      log.fine('Starting Player');
      // const url =
      //     'https://cdn.pixabay.com/download/audio/2022/10/12/audio_061cead49a.mp3?filename=weeknds-122592.mp3';
      // const url =
      //     '/Users/gvpinto/Library/Developer/CoreSimulator/Devices/ED04ABB2-6F8D-426E-AD55-89DFCECAD7D9/data/Containers/Data/Application/4F87065C-1EFB-4802-AA53-E02F0C229082/Documents/episode-43.mp3';
      Duration podcastLength =
          await _myPlayer.startPlayer(fromURI: url) as Duration;

      log.finer('Duration: ${podcastLength.inSeconds}');
      await _myPlayer.setSubscriptionDuration(const Duration(seconds: 2));

      _playerSubscription = _myPlayer.onProgress!.listen((event) {
        // print(event.duration.inSeconds - event.position.inSeconds);
        final progress = event.position.inSeconds / podcastLength.inSeconds;
        log.finer("Progress: $progress");
        setState(() => _playPosition = progress);
      });

      setState(() => _isPlaying = !_myPlayer.isPaused);
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
