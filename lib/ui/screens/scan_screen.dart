import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/bms_provider.dart';
import 'dashboard_screen.dart';
import '../theme.dart';
import '../widgets/glass_container.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _checkPermissions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {
      if (!mounted) return;
      Provider.of<BmsProvider>(context, listen: false).scan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Deep black background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Discover", style: AppTheme.largeTitle),
                  _buildScanIndicator(),
                ],
              ),
            ),

            // List
            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.scanResults,
                initialData: const [],
                builder: (context, snapshot) {
                  final results = snapshot.data ?? [];

                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bluetooth_searching,
                            size: 64,
                            color: AppTheme.systemGrey4,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Searching for BMS...",
                            style: AppTheme.body.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GlassContainer(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              result.device.platformName.isNotEmpty
                                  ? result.device.platformName
                                  : "Unknown Device",
                              style: AppTheme.headline,
                            ),
                            subtitle: Text(
                              result.device.remoteId.toString(),
                              style: AppTheme.label,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${result.rssi}",
                                  style: AppTheme.unit.copyWith(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.signal_cellular_alt,
                                  size: 16,
                                  color: AppTheme.systemBlue,
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.textTertiary,
                                ),
                              ],
                            ),
                            onTap: () =>
                                _connectToDevice(context, result.device),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanIndicator() {
    return StreamBuilder<bool>(
      stream: FlutterBluePlus.isScanning,
      initialData: false,
      builder: (context, snapshot) {
        final isScanning = snapshot.data ?? false;
        if (!isScanning) {
          return IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.systemBlue),
            onPressed: () =>
                Provider.of<BmsProvider>(context, listen: false).scan(),
          );
        }

        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.systemBlue.withValues(
                  alpha: 1.0 - _pulseController.value,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _connectToDevice(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    // Show full-screen blur loading overlay ideally, but dialog for now
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (c) => Center(
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.systemBlue),
              const SizedBox(height: 20),
              Text("Connecting...", style: AppTheme.headline),
            ],
          ),
        ),
      ),
    );

    try {
      await Provider.of<BmsProvider>(context, listen: false).connect(device);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // pop dialog
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // pop dialog
        // Using ScaffodMessenger might lose context if replaced?
        // Safer to show error dialog
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text(
              "Connection Failed",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }
}
