import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bms_provider.dart';
import '../theme.dart';

class CellsScreen extends StatelessWidget {
  const CellsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cell Voltages")),
      body: Consumer<BmsProvider>(
        builder: (context, provider, child) {
          final cells = provider.cellVoltages;
          if (cells == null) {
            return const Center(child: Text("Waiting for cell data..."));
          }

          // Calculate stats
          double maxV = cells.voltages.reduce(
            (curr, next) => curr > next ? curr : next,
          );
          double minV = cells.voltages.reduce(
            (curr, next) => curr < next ? curr : next,
          );
          double diff = maxV - minV;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat("Max", maxV.toStringAsFixed(3), "V"),
                        _buildMiniStat("Min", minV.toStringAsFixed(3), "V"),
                        _buildMiniStat(
                          "Diff",
                          (diff * 1000).toStringAsFixed(0),
                          "mV",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cells.voltages.length,
                  itemBuilder: (context, index) {
                    final voltage = cells.voltages[index];
                    // Color grading for voltage
                    Color barColor = AppTheme.success;
                    if (voltage < 3.0) barColor = AppTheme.error;
                    if (voltage > 4.15) barColor = AppTheme.warning;

                    return ListTile(
                      title: Text("Cell ${index + 1}"),
                      trailing: Text(
                        "${voltage.toStringAsFixed(3)} V",
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: LinearProgressIndicator(
                        value: (voltage - 2.5) / (4.2 - 2.5), // Scale 2.5V-4.2V
                        backgroundColor: Colors.white10,
                        color: barColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: AppTheme.label),
        const SizedBox(height: 4),
        Text(
          "$value $unit",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
