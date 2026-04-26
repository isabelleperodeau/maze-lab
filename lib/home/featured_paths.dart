import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeaturedPath {
  const FeaturedPath({
    required this.pathName,
    required this.description,
    required this.topTime,
    required this.badge,
    required this.badgeColor,
  });

  final String pathName;
  final String description;
  final String topTime;
  final String badge;
  final Color badgeColor;
}

final featuredPathsProvider = Provider<List<FeaturedPath>>((ref) => const [
  FeaturedPath(
    pathName: 'Master Solver',
    description: '🔥 Trending',
    topTime: '2:14',
    badge: 'Trending',
    badgeColor: Colors.orange,
  ),
  FeaturedPath(
    pathName: 'Speed Runner',
    description: '⭐ Featured',
    topTime: '3:45',
    badge: 'Featured',
    badgeColor: Colors.blue,
  ),
  FeaturedPath(
    pathName: 'Logic Master',
    description: '💎 Challenge',
    topTime: '5:22',
    badge: 'Challenge',
    badgeColor: Colors.purple,
  ),
]);

class FeaturedPaths extends ConsumerWidget {
  const FeaturedPaths({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paths = ref.watch(featuredPathsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Featured paths', style: theme.textTheme.titleMedium),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: paths.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _FeaturedPathCard(path: paths[i]),
          ),
        ),
      ],
    );
  }
}

class _FeaturedPathCard extends StatelessWidget {
  const _FeaturedPathCard({required this.path});

  final FeaturedPath path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        path.pathName,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: path.badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        path.badge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: path.badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  path.description,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.leaderboard_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text('Best: ${path.topTime}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
