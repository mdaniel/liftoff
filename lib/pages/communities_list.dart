import 'package:flutter/material.dart';
import 'package:lemmy_api_client/v3.dart';

import '../util/extensions/truncate.dart';
import '../util/goto.dart';
import '../widgets/avatar.dart';
import '../widgets/markdown_text.dart';
import '../widgets/sortable_infinite_list.dart';

/// Infinite list of Communities fetched by the given fetcher
class CommunitiesListPage extends StatelessWidget {
  final String title;
  final FetcherWithSorting<CommunityView> fetcher;

  const CommunitiesListPage({
    super.key,
    required this.fetcher,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        title: Text(title),
      ),
      body: SortableInfiniteList<CommunityView>(
        fetcher: fetcher,
        itemBuilder: (community) => Column(
          children: [
            const Divider(),
            CommunitiesListItem(
              community: community,
            )
          ],
        ),
        uniqueProp: (item) => item.community.actorId,
      ),
    );
  }
}

class CommunitiesListItem extends StatelessWidget {
  final CommunityView community;

  const CommunitiesListItem({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    // Find a reasonable cutoff point for the description.
    var desc = '';
    if (community.community.description != null) {
      desc = community.community.description!.truncate(200);
      final par = desc.indexOf('\n');
      if (par > 0) desc = desc.substring(0, par);
    }

    return ListTile(
      title: Text(community.community.name),
      subtitle: community.community.description != null
          ? Opacity(
              opacity: 0.7,
              child: MarkdownText(
                desc,
                instanceHost: community.instanceHost,
              ),
            )
          : const SizedBox(height: 5),
      onTap: () => goToCommunity.byId(
          context, community.instanceHost, community.community.id),
      leading: Avatar(url: community.community.icon),
    );
  }
}
