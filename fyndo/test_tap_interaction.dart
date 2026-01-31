import 'dart:convert';
import 'dart:io';

void main() async {
  final vmServiceUrl = 'ws://127.0.0.1:52651/_Ixd14vJOg4=/ws';

  print('🎯 MARIONETTE UI INTERACTION TEST\n');
  print('━' * 70);

  try {
    final vmService = await vmServiceConnectUri(vmServiceUrl);
    print('✅ Connected to VM service\n');

    final vm = await vmService.getVM();
    final mainIsolate = vm.isolates!.first;

    // First, take a screenshot to see current state
    print('📸 BEFORE: Taking screenshot...');
    var response = await vmService.callServiceExtension(
      'ext.flutter.marionette.takeScreenshots',
      isolateId: mainIsolate.id,
    );

    if (response.json!['screenshots'] is List &&
        (response.json!['screenshots'] as List).isNotEmpty) {
      final screenshot = (response.json!['screenshots'] as List)[0] as String;
      final bytes = base64.decode(screenshot);
      await File('/tmp/fyndo_before_tap.png').writeAsBytes(bytes);
      print('   Saved to: /tmp/fyndo_before_tap.png\n');
    }

    // Get interactive elements to find something to tap
    print('🔍 Finding interactive elements...');
    response = await vmService.callServiceExtension(
      'ext.flutter.marionette.interactiveElements',
      isolateId: mainIsolate.id,
    );

    final elements = response.json!['elements'] as List;
    print('   Found ${elements.length} elements\n');

    // Look for an InkWell or GestureDetector (likely a button)
    var targetElement = elements.firstWhere(
      (e) => e['type'] == 'InkWell' || e['type'] == 'GestureDetector',
      orElse: () => null,
    );

    if (targetElement != null) {
      print('🎯 Target element found:');
      print('   Type: ${targetElement['type']}');
      print(
        '   Position: (${targetElement['bounds']['x']}, ${targetElement['bounds']['y']})',
      );
      print(
        '   Size: ${targetElement['bounds']['width']} x ${targetElement['bounds']['height']}',
      );

      // Calculate center point
      final centerX =
          targetElement['bounds']['x'] + (targetElement['bounds']['width'] / 2);
      final centerY =
          targetElement['bounds']['y'] +
          (targetElement['bounds']['height'] / 2);

      print('\n👆 Attempting to TAP at ($centerX, $centerY)...');

      try {
        response = await vmService.callServiceExtension(
          'ext.flutter.marionette.tap',
          isolateId: mainIsolate.id,
          args: {'x': centerX, 'y': centerY},
        );

        print('   ✅ Tap executed successfully!');
        print('   Response: ${response.json}');

        // Wait a bit for UI to update
        await Future.delayed(Duration(milliseconds: 500));

        // Take another screenshot
        print('\n📸 AFTER: Taking screenshot...');
        response = await vmService.callServiceExtension(
          'ext.flutter.marionette.takeScreenshots',
          isolateId: mainIsolate.id,
        );

        if (response.json!['screenshots'] is List &&
            (response.json!['screenshots'] as List).isNotEmpty) {
          final screenshot =
              (response.json!['screenshots'] as List)[0] as String;
          final bytes = base64.decode(screenshot);
          await File('/tmp/fyndo_after_tap.png').writeAsBytes(bytes);
          print('   Saved to: /tmp/fyndo_after_tap.png');
        }
      } catch (e) {
        print('   ❌ Tap failed: $e');
      }
    } else {
      print('❌ No suitable element found to tap');
    }

    print('\n' + '━' * 70);
    print('✅ UI INTERACTION TEST COMPLETED!\n');
    print('📁 Compare screenshots:');
    print('   Before: /tmp/fyndo_before_tap.png');
    print('   After:  /tmp/fyndo_after_tap.png');
    print('');
  } catch (e, stack) {
    print('❌ Error: $e');
    print('Stack: $stack');
    exit(1);
  }

  exit(0);
}
