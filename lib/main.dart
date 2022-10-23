import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

const url = "https://itsallwidgets.com/podcast/feed";

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
      home: BoringPage(),
    );
  }
}

class BoringPage extends StatelessWidget {
  const BoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: SafeArea(child: DashCastApp()) //Center(child: PlaybackButton()),
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
            const IconButton(
                onPressed: backward(), icon: Icon(Icons.fast_rewind)),
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
            const IconButton(
                onPressed: forward(), icon: Icon(Icons.fast_forward)),
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

  void backward() {}

  void forward() {}
}

class DashCastApp extends StatelessWidget {
  const DashCastApp({super.key});

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

class PlaybackButtons extends StatelessWidget {
  const PlaybackButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: PlaybackButton(),
    );
  }
}
