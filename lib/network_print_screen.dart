import 'package:flutter/material.dart';
import 'package:printer/print_controller.dart';

class NetworkPrintScreen extends StatefulWidget {
  const NetworkPrintScreen({super.key, required this.title});

  final String title;

  @override
  State<NetworkPrintScreen> createState() => _NetworkPrintScreenState();
}

class _NetworkPrintScreenState extends State<NetworkPrintScreen> {
  @override
  void initState() {
    setState(() {
      PrintController.instance.init();
    });
    super.initState();
  }

  @override
  void dispose() {
    PrintController.instance.close();
    super.dispose();
  }

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
                onChanged: (ip) {
                  setState(() {
                    PrintController.instance.setPort('');
                    PrintController.instance.setIpAddress(ip);
                  });
                },
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
        onPressed: () {
          if (PrintController.instance.selectedPrinter != null) {
            PrintController.instance.printTest();
          }
        },
        tooltip: 'Print',
        child: const Icon(Icons.print),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
