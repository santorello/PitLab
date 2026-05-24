import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_breakpoints.dart';
import 'content_scaffold_header.dart';
import 'environment_banner.dart';

class ContentScaffold extends ConsumerWidget {
  const ContentScaffold({
    required this.title,
    required this.description,
    required this.child,
    this.trailingActions,
    super.key,
  });

  final String title;
  final String description;
  final Widget child;

  /// Widget aggiuntivi inseriti a destra del bottone login/profilo.
  /// Usato ad esempio da TracksHomeScreen per il selettore lingua.
  final List<Widget>? trailingActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidth),
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const EnvironmentBanner(),
                        ContentScaffoldHeader(
                          title: title,
                          description: description,
                          trailingActions: trailingActions,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
