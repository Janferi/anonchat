import 'package:flutter/material.dart';

class PrivateChatListScreen extends StatelessWidget {
  const PrivateChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Chats')),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Anon_Xy9z'),
            subtitle: Text('Hey, are you near the fountain?'),
            trailing: Text('2m ago'),
          ),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Anon_Ab12'),
            subtitle: Text('See you there.'),
            trailing: Text('1h ago'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'To start a private chat, tap a user in a Nearby Room.',
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
