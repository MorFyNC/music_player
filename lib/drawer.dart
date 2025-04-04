import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawerPage extends StatefulWidget {
  final String userId;
  const DrawerPage({super.key, required this.userId} );

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {

  final supabase = Supabase.instance.client;
  dynamic user;

  Future<void> getUsersData() async {
    final response = await supabase
      .from('User')
      .select()
      .eq('id', widget.userId)
      .single();

    setState(() {
      user = response;
    });
  }

  @override
  void initState() {
    getUsersData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        DrawerHeader(
          child: UserAccountsDrawerHeader(accountName: Text(user['login']),
           accountEmail: Text(user['email']), 
           currentAccountPicture: Image.network(user['Image']),
           otherAccountsPictures: [
              IconButton(onPressed: () {}, icon: Icon(Icons.logout))
            ],
          ),
        ),
        ListTile(
          title: Text('Моя музыка'),
        ),
        ListTile(
          title: Text(''),
        ),
        ListTile(
          title: Text(''),
        ),
        ],
    );
  }
}