import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bms_provider.dart';
import 'cells_screen.dart';
import '../theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BmsProvider>(
      builder: (context, provider, child) {
        final info = provider.baseInfo;

        return Scaffold(
          appBar: AppBar(
            title: const Text("OnePack"),
            actions: [
              IconButton(
                icon: const Icon(Icons.grid_on),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CellsScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.power_settings_new),
                onPressed: () {
                  provider.disconnect();
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
            ],
          ),
          body: info == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // SOC Circle
                      Center(
                        child: SizedBox(
                          height: 250,
                          width: 250,
                          child: Stack(
                            children: [
                              // Background Circle
                              const Center(
                                child: SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    color: Colors.white10,
                                    strokeWidth: 20,
                                  ),
                                ),
                              ),
                              // Progress Circle
                              Center(
                                child: SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: CircularProgressIndicator(
                                    value: info.rsoc / 100.0,
                                    color: _getSocColor(info.rsoc),
                                    strokeWidth: 20,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                              ),
                              // Text
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${info.rsoc}%",
                                      style: AppTheme.largeValue,
                                    ),
                                    Text("Capacity", style: AppTheme.label),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Stats Grid
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(
                              "Voltage",
                              info.totalVoltage.toStringAsFixed(1),
                              "V",
                              Colors.white,
                            ),
                            _buildStatCard(
                              "Current",
                              info.current.toStringAsFixed(1),
                              "A",
                              info.current > 0
                                  ? AppTheme.success
                                  : (info.current < 0
                                        ? AppTheme.error
                                        : Colors.white),
                            ),
                            _buildStatCard(
                              "Res. Cap",
                              info.remainingCapacity.toStringAsFixed(2),
                              "Ah",
                              Colors.white,
                            ),
                            _buildStatCard(
                              "Temp",
                              info.temperatures.isNotEmpty
                                  ? info.temperatures.first.toStringAsFixed(0)
                                  : '--',
                              "°C",
                              Colors.orange,
                            ),
                            _buildStatCard(
                              "Cycle",
                              "0",
                              "",
                              Colors.white,
                            ), // Cycle count not in base info
                            _buildStatCard(
                              "Status",
                              _getStatusText(info),
                              "",
                              Colors.blueAccent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Color _getSocColor(int rsoc) {
    if (rsoc > 50) return AppTheme.success;
    if (rsoc > 20) return AppTheme.warning;
    return AppTheme.error;
  }

  String _getStatusText(dynamic info) {
    if (info.isCharging) return "Charging";
    if (info.isDischarging) return "Discharging";
    return "Idle";
  }

  Widget _buildStatCard(
    String title,
    String value,
    String unit,
    Color valueColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: AppTheme.label),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTheme.largeValue.copyWith(
                    fontSize: 32,
                    color: valueColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(unit, style: AppTheme.unit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
