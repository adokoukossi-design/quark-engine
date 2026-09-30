import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  final String name;
  final String bio;
  final String avatarUrl;
  final bool isPro;
  final VoidCallback onFollow;
  final VoidCallback onContact;

  const UserProfileCard(
      {super.key,
      required this.name,
      required this.bio,
      required this.avatarUrl,
      required this.isPro,
      required this.onFollow,
      required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Row(
      children: [
        CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
        Column(
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            Text(bio, style: Theme.of(context).textTheme.bodySmall),
            if (isPro) Chip(label: Text('PRO')),
          ],
        ),
        Column(
          children: [
            ElevatedButton(onPressed: onFollow, child: Text('Suivre')),
            ElevatedButton(onPressed: onContact, child: Text('Contacter')),
          ],
        ),
      ],
    ));
  }
}
