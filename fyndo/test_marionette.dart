import 'dart:io';

void main() async {
  // Connect to the VM service
  final vmServiceUrl = 'ws://127.0.0.1:52651/_Ixd14vJOg4=/ws';

  print('Connecting to VM service: $vmServiceUrl');

  try {
    final vmService = await vmServiceConnectUri(vmServiceUrl);
    print('✅ Connected to VM service successfully!');

    // Get VM info
    final vm = await vmService.getVM();
    print('\n📱 VM Information:');
    print('   Name: ${vm.name}');
    print('   Version: ${vm.version}');
    print('   Isolates: ${vm.isolates?.length ?? 0}');

    // List isolates
    if (vm.isolates != null && vm.isolates!.isNotEmpty) {
      print('\n🔍 Isolates:');
      for (var isolateRef in vm.isolates!) {
        print('   - ${isolateRef.name} (${isolateRef.id})');

        // Get isolate details
        final isolate = await vmService.getIsolate(isolateRef.id!);
        print('     Libraries: ${isolate.libraries?.length ?? 0}');
      }
    }

    print('\n✅ VM Service connection test successful!');
  } catch (e) {
    print('❌ Error connecting to VM service: $e');
    exit(1);
  }

  exit(0);
}
