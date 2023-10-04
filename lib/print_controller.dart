import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as AnotherImage;
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:printer/printer_model.dart';
import 'package:printer/printer_widgets.dart';
import 'package:printer/widget_to_image.dart';

class PrintController {
  PrintController._();
  static final instance = PrintController._();
  PrinterType defaultPrinterType = PrinterType.usb;
  late CapabilityProfile profile;
  late Generator generator;
  var printerManager = PrinterManager.instance;
  StreamSubscription<PrinterDevice>? _subscription;
  StreamSubscription<BTStatus>? _subscriptionBtStatus;
  StreamSubscription<USBStatus>? _subscriptionUsbStatus;
  BTStatus _currentStatus = BTStatus.none;
  USBStatus _currentUsbStatus = USBStatus.none;
  PrinterModel? selectedPrinter;
  bool _isConnected = false;
  var _isBle = false;
  var _reconnect = false;
  List<int>? pendingTask;
  String _ipAddress = '';
  String _port = '9100';
  var _ipController = TextEditingController();
  var _portController = TextEditingController();
  List<PrinterModel> devices = [];

  init() async {
    devices = [];
    profile = await CapabilityProfile.load();
    generator = Generator(PaperSize.mm58, profile);
    if (Platform.isWindows) defaultPrinterType = PrinterType.usb;

    _subscriptionBtStatus =
        PrinterManager.instance.stateBluetooth.listen((status) {
      log(' ----------------- status bt $status ------------------ ');
      _currentStatus = status;
      if (status == BTStatus.connected) {
        _isConnected = true;
      }
      if (status == BTStatus.none) {
        _isConnected = false;
      }
      if (status == BTStatus.connected && pendingTask != null) {
        if (Platform.isAndroid) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            PrinterManager.instance
                .send(type: PrinterType.bluetooth, bytes: pendingTask!);
            pendingTask = null;
          });
        } else if (Platform.isIOS) {
          PrinterManager.instance
              .send(type: PrinterType.bluetooth, bytes: pendingTask!);
          pendingTask = null;
        }
      }
    });
    //  PrinterManager.instance.stateUSB is only supports on Android
    _subscriptionUsbStatus = PrinterManager.instance.stateUSB.listen((status) {
      log(' ----------------- status usb $status ------------------ ');
      _currentUsbStatus = status;
      if (Platform.isAndroid) {
        if (status == USBStatus.connected && pendingTask != null) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            PrinterManager.instance
                .send(type: PrinterType.usb, bytes: pendingTask!);
            pendingTask = null;
          });
        }
      }
    });
  }

  Future<List<PrinterModel>> scan() async {
    devices.clear();
    log('device cleared');
    _subscription = printerManager
        .discovery(type: defaultPrinterType, isBle: false)
        .listen((device) {
      log('New device $device');
      log('New device ${device.name}');
      log('New device ${device.address}');

      devices.add(PrinterModel(
        deviceName: device.name,
        address: device.address,
        isBle: _isBle,
        vendorId: device.vendorId,
        productId: device.productId,
        typePrinter: defaultPrinterType,
      ));
    });
    return devices;
  }

  void setPort(String value) {
    if (value.isEmpty) value = '9100';
    _port = value;
    var device = PrinterModel(
      deviceName: value,
      address: _ipAddress,
      port: _port,
      typePrinter: PrinterType.network,
      state: false,
    );
    selectDevice(device);
  }

  void setIpAddress(String value) {
    _ipAddress = value;
    var device = PrinterModel(
      deviceName: value,
      address: _ipAddress,
      port: _port,
      typePrinter: PrinterType.network,
      state: false,
    );
    selectDevice(device);
  }

  Future<void> selectDevice(PrinterModel device) async {
    if (selectedPrinter != null) {
      if ((device.typePrinter == PrinterType.usb &&
          selectedPrinter!.vendorId != device.vendorId)) {
        await PrinterManager.instance
            .disconnect(type: selectedPrinter!.typePrinter);
      }
    }

    selectedPrinter = device;
    log('selectedPrinter $device');
  }

  Future<void> connectDevice(List<int> bytes) async {
    if (selectedPrinter == null) return;
    var bluetoothPrinter = selectedPrinter!;

    switch (bluetoothPrinter.typePrinter) {
      case PrinterType.usb:
        bytes += generator.feed(2);
        bytes += generator.cut();
        await printerManager.connect(
            type: bluetoothPrinter.typePrinter,
            model: UsbPrinterInput(
                name: bluetoothPrinter.deviceName,
                productId: bluetoothPrinter.productId,
                vendorId: bluetoothPrinter.vendorId));
        pendingTask = null;
        break;
      case PrinterType.bluetooth:
        bytes += generator.cut();
        await printerManager.connect(
            type: bluetoothPrinter.typePrinter,
            model: BluetoothPrinterInput(
                name: bluetoothPrinter.deviceName,
                address: bluetoothPrinter.address!,
                isBle: bluetoothPrinter.isBle ?? false,
                autoConnect: _reconnect));
        pendingTask = null;
        if (Platform.isAndroid) pendingTask = bytes;
        break;
      case PrinterType.network:
        bytes += generator.feed(2);
        bytes += generator.cut();
        await printerManager.connect(
            type: bluetoothPrinter.typePrinter,
            model: TcpPrinterInput(ipAddress: bluetoothPrinter.address!));
        break;
      default:
    }
  }

  printTest() async {
    List<int> ticket = [];

    try {
      await connectDevice(ticket);
      if (_isConnected) {
        ticket = await generateBytes(ticket);
        if (selectedPrinter!.typePrinter == PrinterType.bluetooth &&
            Platform.isAndroid) {
          if (_currentStatus == BTStatus.connected) {
            printerManager.send(
                type: selectedPrinter!.typePrinter, bytes: ticket);
            pendingTask = null;
          }
        } else {
          printerManager.send(
              type: selectedPrinter!.typePrinter, bytes: ticket);
        }
        showSnakeBar('isConnected true');
      } else {
        showSnakeBar('isConnected false');
      }
    } catch (e) {
      showSnakeBar('error is  $e');
      log('error is  $e');
    }
  }

  Future<List<int>> generateBytes(List<int> ticket) async {
    Uint8List? companyNameAs8List = await createImageFromWidget(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            compnayName(),
            branchName(),
            vatNo(),
            cashierNameAndPostingDate(),
            invoiceStatusAndOrderType(),
            orderNo(),
          ],
        ),
        logicalSize: Size(500, 500),
        imageSize: Size(680, 680));
    final AnotherImage.Image companyNameImage =
        AnotherImage.decodeImage(companyNameAs8List!)!;
    // table header
    Uint8List? tableHeaderAs8List = await createImageFromWidget(tableHeader(),
        logicalSize: Size(500, 500), imageSize: Size(680, 680));
    final AnotherImage.Image tableHeaderImage =
        AnotherImage.decodeImage(tableHeaderAs8List!)!;
    // divider
    Uint8List? dividerAs8List = await createImageFromWidget(divider(),
        logicalSize: Size(500, 500), imageSize: Size(680, 680));
    final AnotherImage.Image dividerImage =
        AnotherImage.decodeImage(dividerAs8List!)!;
    // table item row
    Uint8List? tableItemRowAs8List = await createImageFromWidget(tableItemRow(),
        logicalSize: Size(500, 500), imageSize: Size(680, 680));
    final AnotherImage.Image tableItemRowImage =
        AnotherImage.decodeImage(tableItemRowAs8List!)!;
    // table footer
    Uint8List? tableFooterRowAs8List = await createImageFromWidget(
        tableFotter(),
        logicalSize: Size(500, 500),
        imageSize: Size(680, 680));
    final AnotherImage.Image tableFooterImage =
        AnotherImage.decodeImage(tableFooterRowAs8List!)!;
    // invoice ref & print time
    Uint8List? invoiceRefAndPrintTimeAs8List = await createImageFromWidget(
        referenceNoAndPrintTime(),
        logicalSize: Size(500, 500),
        imageSize: Size(680, 680));
    final AnotherImage.Image invoiceRefAndPrintTimerImage =
        AnotherImage.decodeImage(invoiceRefAndPrintTimeAs8List!)!;
    ticket += generator.imageRaster(companyNameImage);
    ticket += generator.imageRaster(tableHeaderImage);
    ticket += generator.imageRaster(dividerImage);
    ticket += generator.imageRaster(tableItemRowImage);
    ticket += generator.imageRaster(tableItemRowImage);
    ticket += generator.imageRaster(tableItemRowImage);
    ticket += generator.imageRaster(dividerImage);
    ticket += generator.imageRaster(tableFooterImage);
    ticket += generator.feed(3);
    ticket += generator.imageRaster(invoiceRefAndPrintTimerImage);
    ticket += generator.feed(2);
    ticket += generator.cut();
    return ticket;
  }

  void close() {
    devices = [];
    selectedPrinter = null;
    _subscription?.cancel();
    _subscriptionBtStatus?.cancel();
    _subscriptionUsbStatus?.cancel();
  }
}
