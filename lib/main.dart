import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:printer/priter_services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Printer Demo By Serag Sakr',
      navigatorKey: appNavigatorKey,
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Printer Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

final ipController = TextEditingController();
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Enter Printer IP Address',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'IP Address',
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          _print();
        },
        tooltip: 'Print',
        child: const Icon(Icons.print),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _print() {
    log(ipController.text);
    printTest(ipController.text);
  }
}
