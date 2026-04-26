import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendChallenge {
  const FriendChallenge({
    required this.friendName,
    required this.pathName,
    required this.bestTime,
    required this.avatarColor,
  });

  final String friendName;
  final String pathName;
  final String bestTime;
  final Color avatarColor;

  String get initial => friendName.isEmpty ? '?' : friendName[0].toUpperCase();
}

final friendChallengesProvider = Provider<List<FriendChallenge>>((ref) => const [
  FriendChallenge(
    friendName: 'Alice',
    pathName: 'Logic Crunch',
    bestTime: '4:32',
    avatarColor: Colors.pinkAccent,
  ),
  FriendChallenge(
    friendName: 'Bob',
    pathName: 'Number Knights',
    bestTime: '7:15',
    avatarColor: Colors.teal,
  ),
  FriendChallenge(
    friendName: 'Casey',
    pathName: 'Grid Hunters',
    bestTime: '6:48',
    avatarColor: Colors.amber,
  ),
]);

class FriendChallenges extends ConsumerWidget {
  const FriendChallenges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(friendChallengesProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Friend challenges', style: theme.textTheme.titleMedium),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: challenges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _ChallengeCard(challenge: challenges[i]),
          ),
        ),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final FriendChallenge challenge;

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
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: challenge.avatarColor,
                  foregroundColor: Colors.white,
                  child: Text(challenge.initial),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        challenge.friendName,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        challenge.pathName,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(challenge.bestTime, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
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