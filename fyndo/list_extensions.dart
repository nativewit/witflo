import 'dart:io';

void main() async {
  final vmServiceUrl = 'ws://127.0.0.1:52651/_Ixd14vJOg4=/ws';

  print('🔗 Connecting to VM service...\n');

  try {
    final vmService = await vmServiceConnectUri(vmServiceUrl);
    print('✅ Connected!\n');

    final vm = await vmService.getVM();
    final mainIsolate = vm.isolates!.first;
    final isolate = await vmService.getIsolate(mainIsolate.id!);

    print('📋 Available Service Extensions:\n');
    print('━' * 60);

    if (isolate.extensionRPCs != null && isolate.extensionRPCs!.isNotEmpty) {
      for (var ext in isolate.extensionRPCs!) {
        print('   • $ext');
      }
    } else {
      print('   No extensions registered');
    }

    print('\n' + '━' * 60);
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }

  exit(0);
}
