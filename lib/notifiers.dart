import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webfeed/webfeed.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

const pathSuffix = '/dashcast/downloads';

class PodCast with ChangeNotifier {
  final log = Logger('PodCast');
  late EpisodeFeed _feed;
  Episode? _selectedItem;
  bool _init = false;

  Future<void> parse(Uri url) async {
    final response = await http.get(url);
    String? xmlString = response.body;
    _feed = EpisodeFeed.parse(xmlString);
    _init = true;
    notifyListeners();
  }

  EpisodeFeed get feed => _feed;

  bool get initialize => _init;

  set feed(EpisodeFeed value) {
    _feed = value;
    notifyListeners();
  }

  Episode? get item => _selectedItem;

  set selectedItem(Episode? value) {
    _selectedItem = value;
    notifyListeners();
  }
}

class EpisodeFeed {
  List<Episode> items = [];
  // final RssImage? image;
  final RssFeed feed;

  EpisodeFeed({required this.feed}) {
    //: image = feed.image {
    items = feed.items!.map((item) => Episode(item)).toList();
  }

  get image => feed.image!;

  static EpisodeFeed parse(xmlStr) {
    var feed = RssFeed.parse(xmlStr);
    return EpisodeFeed(feed: feed);
  }
}

class Episode extends RssItem with ChangeNotifier {
  final log = Logger('Episode');
  String downloadPath = '';

  Episode(RssItem item)
      : super(
            title: item.title,
            description: item.description,
            link: item.link,
            categories: item.categories,
            guid: item.guid,
            pubDate: item.pubDate,
            author: item.author,
            comments: item.comments,
            source: item.source,
            content: item.content,
            media: item.media,
            enclosure: item.enclosure,
            dc: item.dc,
            itunes: item.itunes);

  // Future<bool> download(RssItem item, [Function(double)? updates]) async {
  Future<void> download([Function(double)? updates]) async {
    var client = http.Client();
    var downloadLength = 0;
    // bool success = false;

    final res = await client.send(http.Request('GET', Uri.parse(guid!)));

    if (res.statusCode != 200) {
      throw Exception('Unexpected HTTP code: ${res.statusCode}');
    }

    final filePath = await _getDownloadPath(path.split(guid!).last);

    final file = File(filePath);

    // await res.stream
    res.stream
        .map((chunk) {
          downloadLength += chunk.length;
          if (updates != null) {
            updates(downloadLength / 1);
          }

          log.finer('Download size: $downloadLength');
          return chunk;
        })
        .pipe(file.openWrite())
        .whenComplete(() {
          // TODO: save this to share preferences
          downloadPath = filePath;
          client.close();
          // success = true;
          log.fine('Download Complete');
        });

    // return success;
    // res.stream.listen((value) {
    //   print('Bytes: ${value.length}');
    // });
  }

  Future<String> _getDownloadPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final prefix = dir.path;
    final filePath = path.join(prefix, filename);
    // print('FilePath: ${filePath}');
    return filePath;
  }
}
