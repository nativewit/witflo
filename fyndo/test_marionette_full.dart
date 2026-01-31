import 'dart:convert';
import 'dart:io';

void main() async {
  final vmServiceUrl = 'ws://127.0.0.1:52651/_Ixd14vJOg4=/ws';

  print('🎯 MARIONETTE MCP CAPABILITIES TEST\n');
  print('━' * 70);

  try {
    final vmService = await vmServiceConnectUri(vmServiceUrl);
    print('✅ Connected to VM service\n');

    final vm = await vmService.getVM();
    final mainIsolate = vm.isolates!.first;

    // Test 1: Take Screenshot
    print('1️⃣  SCREENSHOT CAPTURE TEST');
    print('─' * 70);
    try {
      final response = await vmService.callServiceExtension(
        'ext.flutter.marionette.takeScreenshots',
        isolateId: mainIsolate.id,
      );

      if (response.json != null) {
        print('   Raw response keys: ${response.json!.keys}');

        if (response.json!.containsKey('screenshots')) {
          final screenshots = response.json!['screenshots'];
          print('   ✅ Screenshot data received!');
          print('   Type: ${screenshots.runtimeType}');

          if (screenshots is List) {
            print('   📊 Number of screenshots: ${screenshots.length}');

            for (var i = 0; i < screenshots.length; i++) {
              final screenshot = screenshots[i];
              print('   Screenshot $i type: ${screenshot.runtimeType}');

              // Try different data structures
              String? imageData;
              if (screenshot is String) {
                imageData = screenshot;
              } else if (screenshot is Map && screenshot.containsKey('image')) {
                imageData = screenshot['image'] as String;
              }

              if (imageData != null) {
                final bytes = base64.decode(imageData);
                final file = File('/tmp/fyndo_marionette_$i.png');
                await file.writeAsBytes(bytes);

                print('   ✅ Screenshot $i saved: ${file.path}');
                print(
                  '      Size: ${(bytes.length / 1024).toStringAsFixed(2)} KB',
                );
              }
            }
          } else if (screenshots is String) {
            // Single screenshot as base64 string
            final bytes = base64.decode(screenshots);
            final file = File('/tmp/fyndo_marionette.png');
            await file.writeAsBytes(bytes);

            print('   ✅ Screenshot saved: ${file.path}');
            print('      Size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
          }
        }
      }
    } catch (e, stack) {
      print('   ❌ Screenshot failed: $e');
      print('   Stack: ${stack.toString().split('\n').take(3).join('\n   ')}');
    }

    // Test 2: Get Interactive Elements
    print('\n2️⃣  INTERACTIVE ELEMENTS INSPECTION');
    print('─' * 70);
    try {
      final response = await vmService.callServiceExtension(
        'ext.flutter.marionette.interactiveElements',
        isolateId: mainIsolate.id,
      );

      if (response.json != null && response.json!.containsKey('elements')) {
        final elements = response.json!['elements'] as List;
        print('   ✅ Found ${elements.length} interactive elements\n');

        for (var i = 0; i < elements.length && i < 15; i++) {
          final element = elements[i];
          print('   Element $i:');
          print('      Type: ${element['type']}');
          if (element['text'] != null &&
              element['text'].toString().isNotEmpty) {
            print('      Text: "${element['text']}"');
          }
          if (element['key'] != null) {
            print('      Key: ${element['key']}');
          }
          if (element['bounds'] != null) {
            final bounds = element['bounds'];
            print('      Position: (${bounds['x']}, ${bounds['y']})');
            print('      Size: ${bounds['width']} x ${bounds['height']}');
          }
          print('');
        }
      }
    } catch (e, stack) {
      print('   ❌ Interactive elements failed: $e');
    }

    // Test 3: Get Logs
    print('\n3️⃣  APPLICATION LOGS');
    print('─' * 70);
    try {
      final response = await vmService.callServiceExtension(
        'ext.flutter.marionette.getLogs',
        isolateId: mainIsolate.id,
      );

      if (response.json != null) {
        print('   Response type: ${response.json.runtimeType}');
        print('   Keys: ${response.json!.keys}');

        if (response.json!.containsKey('logs')) {
          final logs = response.json!['logs'];
          print('   Logs type: ${logs.runtimeType}');

          if (logs is List) {
            print('   ✅ Retrieved ${logs.length} log entries\n');

            for (var i = 0; i < logs.length && i < 10; i++) {
              final log = logs[i];
              if (log is String) {
                print('   $log');
              } else if (log is Map) {
                print('   [${log['level'] ?? 'INFO'}] ${log['message']}');
              }
            }
          }
        }
      }
    } catch (e, stack) {
      print('   ❌ Logs retrieval failed: $e');
    }

    print('\n' + '━' * 70);
    print('✅ MARIONETTE MCP TEST COMPLETED!\n');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }

  exit(0);
}
