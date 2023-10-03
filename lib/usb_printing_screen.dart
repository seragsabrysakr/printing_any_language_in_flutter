import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:printer/print_controller.dart';

class UspPrintingScreen extends StatefulWidget {
  const UspPrintingScreen({super.key, required this.title});

  final String title;

  @override
  State<UspPrintingScreen> createState() => _UspPrintingScreenState();
}

class _UspPrintingScreenState extends State<UspPrintingScreen> {
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
            const SizedBox(
              height: 50,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Selected Printer is ${PrintController.instance.selectedPrinter?.deviceName ?? 'Null'}',
                style: const TextStyle(fontSize: 30),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Devices List is ${PrintController.instance.devices.length}',
                style: const TextStyle(fontSize: 30),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            SizedBox(
              height: 500,
              child: ListView.builder(
                  itemCount: PrintController.instance.devices.length,
                  itemBuilder: (context, index) {
                    final item = PrintController.instance.devices[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        onTap: () {
                          PrintController.instance.selectDevice(item);
                        },
                        leading: Text(item.state.toString()),
                        title: Text(item.deviceName.toString()),
                        subtitle: Text(item.vendorId.toString()),
                      ),
                    );
                  }),
            ),
            const Spacer(
              flex: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const SizedBox(
                  width: 50,
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      PrintController.instance.scan();
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text(
                      'Scan',
                      style: TextStyle(fontSize: 25),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 50,
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (PrintController.instance.selectedPrinter != null) {
                        PrintController.instance.printTest();
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text(
                      'Print',
                      style: TextStyle(fontSize: 25),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 50,
                ),
              ],
            ),
            const SizedBox(
              height: 50,
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
