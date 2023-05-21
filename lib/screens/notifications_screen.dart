import 'package:flutter/material.dart';
import 'package:finapp/bankings/monobank_api.dart';

class NotificationsScreen extends StatefulWidget {
  final MonobankApi monobankApi;

  const NotificationsScreen({Key? key, required this.monobankApi})
      : super(key: key); 
  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Повідомлення'),
      ),
      body: const Center(
        child: Text(
          'This is an empty screen.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
