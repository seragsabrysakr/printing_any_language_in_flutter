import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:printer/screens/bluetooth_printing_screen.dart';
import 'package:printer/screens/network_print_screen.dart';
import 'package:printer/printing_service/print_controller.dart';
import 'package:printer/screens/usb_printing_screen.dart';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Printer Usb Demo By Serag Sakr',
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Printer  Demo By Serag Sakr'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  appNavigatorKey.currentState!.push(MaterialPageRoute(
                      builder: (context) => const NetworkPrintScreen(
                            title: 'Network Print Screen',
                          )));
                },
                label: const Text('Network Print Screen'),
                icon: const Icon(Icons.network_check_rounded),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                  onPressed: () {
                    appNavigatorKey.currentState!.push(MaterialPageRoute(
                        builder: (context) => const UspPrintingScreen(
                              title: 'Usp Printing Screen',
                            )));
                  },
                  icon: const Icon(Icons.usb),
                  label: const Text('Usp Printing Screen')),
            ),
            const SizedBox(
              height: 50,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                  onPressed: () {
                    appNavigatorKey.currentState!.push(MaterialPageRoute(
                        builder: (context) => const BluetoothPrintingScreen(
                              title: 'Bluetooth Printing Screen',
                            )));
                  },
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('Bluetooth Printing Screen')),
            ),
          ],
        ),
      ),
    );
  }
}
