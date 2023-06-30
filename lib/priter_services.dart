// ignore_for_file: library_prefixes

import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as AnotherImage;
import 'package:printer/printer_widgets.dart';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

printTest(String ip) async {
  log('printTest');
  try {
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printerService = NetworkPrinter(paper, profile);
    log('connecting');
    final PosPrintResult res = await printerService.connect(ip, port: 9100);
    if (res == PosPrintResult.success) {
      log('connected');
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
      final AnotherImage.Image companyNameImage = AnotherImage.decodeImage(companyNameAs8List!)!;
      // table header
      Uint8List? tableHeaderAs8List = await createImageFromWidget(tableHeader(), logicalSize: Size(500, 500), imageSize: Size(680, 680));
      final AnotherImage.Image tableHeaderImage = AnotherImage.decodeImage(tableHeaderAs8List!)!;
      // divider
      Uint8List? dividerAs8List = await createImageFromWidget(divider(), logicalSize: Size(500, 500), imageSize: Size(680, 680));
      final AnotherImage.Image dividerImage = AnotherImage.decodeImage(dividerAs8List!)!;
      // table item row
      Uint8List? tableItemRowAs8List = await createImageFromWidget(tableItemRow(), logicalSize: Size(500, 500), imageSize: Size(680, 680));
      final AnotherImage.Image tableItemRowImage = AnotherImage.decodeImage(tableItemRowAs8List!)!;
      // table footer
      Uint8List? tableFooterRowAs8List = await createImageFromWidget(tableFotter(), logicalSize: Size(500, 500), imageSize: Size(680, 680));
      final AnotherImage.Image tableFooterImage = AnotherImage.decodeImage(tableFooterRowAs8List!)!;
      // invoice ref & print time
      Uint8List? invoiceRefAndPrintTimeAs8List =
          await createImageFromWidget(referenceNoAndPrintTime(), logicalSize: Size(500, 500), imageSize: Size(680, 680));
      final AnotherImage.Image invoiceRefAndPrintTimerImage = AnotherImage.decodeImage(invoiceRefAndPrintTimeAs8List!)!;

      printerService.image(companyNameImage);
      printerService.image(tableHeaderImage);
      printerService.image(dividerImage);
      printerService.image(tableItemRowImage);
      printerService.image(tableItemRowImage);
      printerService.image(tableItemRowImage);
      printerService.image(dividerImage);
      printerService.image(tableFooterImage);
      printerService.emptyLines(3);
      printerService.image(invoiceRefAndPrintTimerImage);
      printerService.feed(1);
      printerService.cut();
      printerService.disconnect();
    }
    log('res value: ${res.value}');
    log('res msg: ${res.msg}');
  } catch (e, stackTrace) {
    log(e.toString(), stackTrace: stackTrace);
  }
}

Future<Uint8List?> createImageFromWidget(Widget widget, {Duration? wait, Size? logicalSize, Size? imageSize}) async {

  var cxt = appNavigatorKey.currentState!.context;
// Create a repaint boundary to capture the image
  final repaintBoundary = RenderRepaintBoundary();

// Calculate logicalSize and imageSize if not provided
  logicalSize ??= View.of(cxt).physicalSize / View.of(cxt).devicePixelRatio;
  imageSize ??= View.of(cxt).physicalSize;

// Ensure logicalSize and imageSize have the same aspect ratio
  assert(logicalSize.aspectRatio == imageSize.aspectRatio, 'logicalSize and imageSize must not be the same');

// Create the render tree for capturing the widget as an image
  final renderView = RenderView(
    view: View.of(cxt),
    child: RenderPositionedBox(alignment: Alignment.center, child: repaintBoundary),
    configuration: ViewConfiguration(
      size: logicalSize,
      devicePixelRatio: 1,
    ),
  );

  final pipelineOwner = PipelineOwner();
  final buildOwner = BuildOwner(focusManager: FocusManager());

  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

// Attach the widget's render object to the render tree
  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      )).attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);

// Delay if specified
  if (wait != null) {
    await Future.delayed(wait);
  }

// Build and finalize the render tree
  buildOwner
    ..buildScope(rootElement)
    ..finalizeTree();

// Flush layout, compositing, and painting operations
  pipelineOwner
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();

// Capture the image and convert it to byte data
  final image = await repaintBoundary.toImage(pixelRatio: imageSize.width / logicalSize.width);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

// Return the image data as Uint8List
  return byteData?.buffer.asUint8List();
}
