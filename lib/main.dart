import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

final Uri url = Uri.parse("https://itsallwidgets.com/podcast/feed");

const pathSuffix = '/dashcast/downloads';

Future<String> _getDownloadPath(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final prefix = dir.path;
  final filePath = path.join(prefix, filename);
  print('FilePath: ${filePath}');
  return filePath;
}

class PodCast with ChangeNotifier {
  RssFeed? _feed;
  RssItem? _selectedItem;
  Map<String, bool>? downloadStatus;

  void parse(Uri url) async {
    final response = await http.get(url);
    String? xmlString = response.body;
    _feed = RssFeed.parse(xmlString);
    notifyListeners();
  }

  RssFeed? get feed => _feed;

  set feed(RssFeed? value) {
    _feed = value;
    notifyListeners();
  }

  RssItem? get item => _selectedItem;

  set selectedItem(RssItem? value) {
    _selectedItem = value;
    notifyListeners();
  }

  Future<void> download(RssItem item) async {
    var client = http.Client();

    final res = await client.send(http.Request('GET', Uri.parse(item.guid!)));

    if (res.statusCode != 200) {
      throw Exception('Unexpected HTTP code: ${res.statusCode}');
    }

    final file = File(await _getDownloadPath(path.split(item.guid!).last));
    res.stream.pipe(file.openWrite()).whenComplete(() {
      client.close();
      print('Download Complete');
    });

    // res.stream.listen((value) {
    //   print('Bytes: ${value.length}');
    // });
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => PodCast()..parse(url),
      child: const MaterialApp(
        title: 'The Boring Show',
        home: EpisodesPage(),
      ),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  const EpisodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PodCast>(
        builder: (context, podcast, child) {
          return podcast.feed != null
              ? EpisodeListView(rssFeed: podcast.feed)
              : const Center(
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

  final RssFeed? rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed!.items!
          .map(
            (i) => ListTile(
              title: Text(i.title!),
              subtitle: Text(
                i.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_downward),
                onPressed: () {
                  try {
                    context.read<PodCast>().download(i);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading! ${i.title}'),
                      ),
                    );
                  } on Exception catch (e) {
                    print(e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error when downloading'),
                      ),
                    );
                  }
                },
              ),
              onTap: () {
                context.read<PodCast>().selectedItem = i;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => const PlayerPage()),
                ));
              },
            ),
          )
          .toList(),
    );
  }
}

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.read<PodCast>().item!.title!),
      ),
      body: const SafeArea(
        child: Player(),
      ), //Center(child: PlaybackButton()),
    );
  }
}

class Player extends StatelessWidget {
  const Player({super.key});

  @override
  Widget build(BuildContext context) {
    final PodCast podcast = context.read<PodCast>();
    return Column(
      children: <Widget>[
        Flexible(
          flex: 5,
          child: Image.network(podcast.feed!.image!.url!),
        ),
        Flexible(
          flex: 4,
          child: SingleChildScrollView(
            child: Text(podcast.item!.description!),
          ),
        ),
        const Flexible(flex: 2, child: AudioControls()),
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
    final String url = context.read<PodCast>().item!.guid!;

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
    super.dispose();
  }

  void _stop() {
    _myPlayer.pausePlayer();
    setState(() => _isPlaying = false);
  }

  void _play(String url) async {
    if (_myPlayerInit && _myPlayer.isPaused) {
      _myPlayer.resumePlayer();
    } else {
      // const url =
      //     'https://cdn.pixabay.com/download/audio/2022/10/12/audio_061cead49a.mp3?filename=weeknds-122592.mp3';
      const url =
          '/Users/gvpinto/Library/Developer/CoreSimulator/Devices/ED04ABB2-6F8D-426E-AD55-89DFCECAD7D9/data/Containers/Data/Application/4F87065C-1EFB-4802-AA53-E02F0C229082/Documents/episode-43.mp3';
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
