import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/bms_provider.dart';
import 'dashboard_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Check if permission granted
    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {
      if (!mounted) return;
      Provider.of<BmsProvider>(context, listen: false).scan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discover Devices"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<BmsProvider>(context, listen: false).scan();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ScanResult>>(
        stream: FlutterBluePlus.scanResults,
        initialData: const [],
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final results = snapshot.data ?? [];

          if (results.isEmpty) {
            return const Center(
              child: Text("No devices found. Pull to refresh."),
            );
          }

          return ListView.separated(
            itemCount: results.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Colors.white10),
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                title: Text(
                  result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : "Unknown Device",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(result.device.remoteId.toString()),
                trailing: Text("${result.rssi} dBm"),
                onTap: () async {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) => const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text("Connecting..."),
                              Text(
                                "Discovering Services...",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

                  try {
                    debugPrint(
                      "UI: Starting connection to ${result.device.remoteId}",
                    );
                    await Provider.of<BmsProvider>(
                      context,
                      listen: false,
                    ).connect(result.device);
                    debugPrint("UI: Connection successful");

                    if (!context.mounted) return;
                    // Pop the loading dialog
                    Navigator.of(context).pop();

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  } catch (e) {
                    debugPrint("UI: Connection failed: $e");
                    if (context.mounted) {
                      // Pop the loading dialog
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Connection failed: $e"),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
