import 'dart:convert';
import 'dart:io';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart test_mcp_capabilities.dart <vm_service_uri>');
    exit(1);
  }

  final vmServiceUrl = args[0];

  print('🔗 Connecting to VM service: $vmServiceUrl\n');

  try {
    final vmService = await vmServiceConnectUri(vmServiceUrl);
    print('✅ Connected to VM service successfully!\n');

    // Get VM info
    final vm = await vmService.getVM();
    final mainIsolate = vm.isolates!.first;

    print('📱 Testing Marionette MCP Capabilities:\n');
    print('━' * 60);

    // Test 1: Try to get Flutter extension methods
    print('\n1️⃣ Testing Flutter Extension Services...');
    try {
      final extensions = await vmService.callServiceExtension(
        'ext.flutter.inspector.getRootWidgetTree',
        isolateId: mainIsolate.id,
      );
      print('   ✅ Flutter inspector available');
      print('   Response keys: ${extensions.json?.keys.join(", ")}');
    } catch (e) {
      print('   ⚠️  Flutter inspector not available: $e');
    }

    // Test 2: Try to get screenshot via Flutter
    print('\n2️⃣ Testing Screenshot Capability...');
    try {
      final screenshot = await vmService.callServiceExtension(
        'ext.flutter.screenshot',
        isolateId: mainIsolate.id,
      );

      if (screenshot.json != null &&
          screenshot.json!.containsKey('screenshot')) {
        final screenshotData = screenshot.json!['screenshot'] as String;
        final bytes = base64.decode(screenshotData);
        print('   ✅ Screenshot captured!');
        print(
          '   Size: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(2)} KB)',
        );

        // Save screenshot
        final file = File('/tmp/fyndo_screenshot.png');
        await file.writeAsBytes(bytes);
        print('   💾 Saved to: ${file.path}');
      }
    } catch (e) {
      print('   ⚠️  Screenshot failed: $e');
    }

    // Test 3: Get widget tree summary
    print('\n3️⃣ Testing Widget Tree Inspection...');
    try {
      final widgetTree = await vmService.callServiceExtension(
        'ext.flutter.inspector.getRootWidgetSummaryTree',
        isolateId: mainIsolate.id,
        args: {'groupName': 'marionette-test'},
      );
      print('   ✅ Widget tree accessible');
      if (widgetTree.json != null) {
        print('   Keys: ${widgetTree.json!.keys.join(", ")}');
      }
    } catch (e) {
      print('   ⚠️  Widget tree inspection failed: $e');
    }

    // Test 4: Check if Marionette binding is active
    print('\n4️⃣ Testing Marionette Binding...');
    try {
      final services = await vmService.streamListen('Extension');
      print('   ✅ Extension stream available');

      // Try Marionette-specific extension
      final marionette = await vmService.callServiceExtension(
        'ext.marionette.getInteractiveElements',
        isolateId: mainIsolate.id,
      );

      print('   ✅ Marionette binding detected!');
      print('   Response: ${marionette.json}');
    } catch (e) {
      print('   ⚠️  Marionette extension: $e');
    }

    print('\n' + '━' * 60);
    print('\n✅ MCP capability test completed!\n');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }

  exit(0);
}
