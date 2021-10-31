import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lemmy_api_client/v3.dart';

import '../../hooks/logged_in_action.dart';
import '../../stores/accounts_store.dart';
import '../../util/async_store_listener.dart';
import '../../util/extensions/api.dart';
import '../../util/icons.dart';
import '../../util/observer_consumers.dart';
import '../../util/share.dart';
import '../../widgets/post/post.dart';
import '../../widgets/post/post_more_menu.dart';
import '../../widgets/post/post_store.dart';
import '../../widgets/post/save_post_button.dart';
import '../../widgets/reveal_after_scroll.dart';
import '../../widgets/write_comment.dart';
import 'comment_section.dart';
import 'full_post_store.dart';

/// Displays a post with its comment section
class FullPostPage extends HookWidget {
  const FullPostPage._();

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    final loggedInAction =
        useLoggedInAction(context.read<FullPostStore>().instanceHost);

    return AsyncStoreListener(
      asyncStore: context.read<FullPostStore>().fullPostState,
      child: AsyncStoreListener<BlockedCommunity>(
        asyncStore: context.read<FullPostStore>().communityBlockingState,
        successMessageBuilder: (context, data) {
          final name = data.communityView.community.originPreferredName;
          return '${data.blocked ? 'Blocked' : 'Unblocked'} $name';
        },
        child: ObserverBuilder<FullPostStore>(
          builder: (context, store) {
            Future<void> refresh() async {
              unawaited(HapticFeedback.mediumImpact());
              await store.refresh(context
                  .read<AccountsStore>()
                  .defaultUserDataFor(store.instanceHost)
                  ?.jwt);
            }

            final postStore = store.postStore;

            if (postStore == null) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: (store.fullPostState.isLoading)
                      ? const CircularProgressIndicator.adaptive()
                      : FailedToLoad(
                          message: 'Post failed to load', refresh: refresh),
                ),
              );
            }

            final post = postStore.postView;

            // VARIABLES

            sharePost() => share(post.post.apId, context: context);

            comment() async {
              final newComment = await Navigator.of(context).push(
                WriteComment.toPostRoute(post.post),
              );

              if (newComment != null) {
                store.addComment(newComment);
              }
            }

            return Scaffold(
                appBar: AppBar(
                  centerTitle: false,
                  title: RevealAfterScroll(
                    scrollController: scrollController,
                    after: 65,
                    child: Text(
                      post.community.originPreferredName,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  actions: [
                    IconButton(icon: Icon(shareIcon), onPressed: sharePost),
                    Provider.value(
                      value: postStore,
                      child: const SavePostButton(),
                    ),
                    IconButton(
                      icon: Icon(moreIcon),
                      onPressed: () => PostMoreMenuButton.show(
                        context: context,
                        postStore: postStore,
                        fullPostStore: store,
                      ),
                    ),
                  ],
                ),
                floatingActionButton: post.post.locked
                    ? null
                    : FloatingActionButton(
                        onPressed: loggedInAction((_) => comment()),
                        child: const Icon(Icons.comment),
                      ),
                body: RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 15),
                      PostTile.fromPostStore(postStore),
                      const CommentSection(),
                    ],
                  ),
                ));
          },
        ),
      ),
    );
  }

  static Jwt? _tryGetJwt(BuildContext context, String instanceHost) {
    return context.read<AccountsStore>().defaultUserDataFor(instanceHost)?.jwt;
  }

  static Route route(int id, String instanceHost) => MaterialPageRoute(
        builder: (context) => Provider(
          create: (context) =>
              FullPostStore(instanceHost: instanceHost, postId: id)
                ..refresh(_tryGetJwt(context, instanceHost)),
          child: const FullPostPage._(),
        ),
      );

  static Route fromPostViewRoute(PostView postView) => MaterialPageRoute(
        builder: (context) => Provider(
          create: (context) => FullPostStore.fromPostView(postView)
            ..refresh(_tryGetJwt(context, postView.instanceHost)),
          child: const FullPostPage._(),
        ),
      );
  static Route fromPostStoreRoute(PostStore postStore) => MaterialPageRoute(
        builder: (context) => Provider(
          create: (context) => FullPostStore.fromPostStore(postStore)
            ..refresh(_tryGetJwt(context, postStore.postView.instanceHost)),
          child: const FullPostPage._(),
        ),
      );
}

class FailedToLoad extends StatelessWidget {
  final String message;
  final VoidCallback refresh;

  const FailedToLoad({required this.refresh, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('try again'),
        )
      ],
    );
  }
}
