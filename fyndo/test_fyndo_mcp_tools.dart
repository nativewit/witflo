// Test script for custom Fyndo MCP tools
// Run this to verify that custom MCP tools are registered and working
//
// Usage:
//   1. Start Flutter app: fvm flutter run -d macos
//   2. Copy VM Service URI from console
//   3. Run: fvm dart test_fyndo_mcp_tools.dart <VM_SERVICE_URI>
//
// Example:
//   fvm dart test_fyndo_mcp_tools.dart ws://127.0.0.1:54321/ABC=/ws

import 'dart:convert';
import 'dart:io';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Error: VM Service URI required');
    print('');
    print('Usage: dart test_fyndo_mcp_tools.dart <VM_SERVICE_URI>');
    print('');
    print('Example:');
    print('  dart test_fyndo_mcp_tools.dart ws://127.0.0.1:54321/ABC=/ws');
    exit(1);
  }

  final uri = args[0];
  print('🔌 Connecting to VM Service: $uri');
  print('');

  try {
    final vmService = await vmServiceConnectUri(uri);
    print('✅ Connected to VM Service');

    final vm = await vmService.getVM();
    final mainIsolate = vm.isolates!.first;
    print('📱 Main isolate: ${mainIsolate.name}');
    print('');

    // List all registered service extensions
    print('📋 Listing all service extensions...');
    final response = await vmService.streamListen(EventStreams.kExtension);
    print('✅ Listening for extensions');
    print('');

    // Test each custom Fyndo MCP tool
    final tools = [
      'get_vault_state',
      'verify_sync_state',
      'check_crypto_health',
      'check_hierarchy_integrity',
      'get_app_state',
      'get_database_stats',
    ];

    print('🧪 Testing ${tools.length} custom Fyndo MCP tools...');
    print('═' * 80);
    print('');

    for (final toolName in tools) {
      await testMCPTool(vmService, mainIsolate.id!, toolName);
      print('');
    }

    print('═' * 80);
    print('✅ All tests completed!');

    await vmService.dispose();
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<void> testMCPTool(
  VmService vmService,
  String isolateId,
  String toolName,
) async {
  print('🔍 Testing: $toolName');

  try {
    final extensionName = 'ext.mcp.toolkit.$toolName';
    final response = await vmService.callServiceExtension(
      extensionName,
      isolateId: isolateId,
    );

    print('   ✅ Extension found: $extensionName');

    if (response.json != null) {
      final jsonStr = JsonEncoder.withIndent('  ').convert(response.json);
      print('   📊 Response:');
      print('   $jsonStr');
    } else {
      print('   ⚠️  No JSON response');
    }
  } catch (e) {
    print('   ❌ Error calling $toolName: $e');
  }
}
