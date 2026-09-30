import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final bool isPro;
  final VoidCallback onFollow;

  const UserProfileCard(
      {super.key,
      required this.name,
      required this.avatarUrl,
      required this.isPro,
      required this.onFollow});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Row(
      children: [
        CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
        Column(
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            if (isPro) Chip(label: Text('PRO')),
          ],
        ),
        ElevatedButton(onPressed: onFollow, child: Text('Suivre')),
      ],
    ));
  }
}
