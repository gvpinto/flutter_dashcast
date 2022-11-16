import 'package:flutter/material.dart';
import 'package:flutter_dashcast/notifiers.dart';
import 'package:flutter_dashcast/player.dart';
import 'package:provider/provider.dart';

class EpisodesPage extends StatelessWidget {
  const EpisodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PodCast>(
      builder: (context, podcast, child) {
        return podcast.initialize
            ? EpisodeListView(episodeFeed: podcast.feed)
            : const Center(
                child: CircularProgressIndicator(),
              );
      },
    );
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
    Key? key,
    required this.episodeFeed,
  }) : super(key: key);

  final EpisodeFeed episodeFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: episodeFeed.items
          .map(
            (i) => ListTile(
              title: Text(i.title!),
              subtitle: Text(
                i.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              // TODO: Need to add consumer and a provider
              trailing: IconButton(
                icon: const Icon(Icons.arrow_downward),
                onPressed: () {
                  // context.read<PodCast>().download(i);
                  i.download().then((value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading! ${i.title}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  });

                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(
                  //     content: Text('Downloading! ${i.title}'),
                  //   ),
                  // );
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
