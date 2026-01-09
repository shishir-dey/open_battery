import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../providers/bms_provider.dart';
import '../theme.dart';
import '../widgets/glass_container.dart';

class CellsScreen extends StatelessWidget {
  const CellsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: SafeArea(
        child: Consumer<BmsProvider>(
          builder: (context, provider, child) {
            final cells = provider.cellVoltages;

            // Calculate stats
            double maxV = 0;
            double minV = 0;
            double diff = 0;
            double avg = 0;

            if (cells != null && cells.voltages.isNotEmpty) {
              maxV = cells.voltages.reduce(
                (curr, next) => curr > next ? curr : next,
              );
              minV = cells.voltages.reduce(
                (curr, next) => curr < next ? curr : next,
              );
              diff = maxV - minV;
              avg =
                  cells.voltages.fold(0.0, (p, c) => p + c) /
                  cells.voltages.length;
            }

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(child: Text("Cells", style: AppTheme.title2)),
                    ],
                  ),
                ),

                // Summary Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat(
                            "Max",
                            cells != null && cells.voltages.isNotEmpty
                                ? maxV.toStringAsFixed(3)
                                : "--",
                            "V",
                            AppTheme.systemRed,
                          ),
                          _buildMiniStat(
                            "Min",
                            cells != null && cells.voltages.isNotEmpty
                                ? minV.toStringAsFixed(3)
                                : "--",
                            "V",
                            AppTheme.systemBlue,
                          ),
                          _buildMiniStat(
                            "Diff",
                            cells != null && cells.voltages.isNotEmpty
                                ? (diff * 1000).toStringAsFixed(0)
                                : "--",
                            "mV",
                            (cells != null && diff > 0.02)
                                ? AppTheme.warning
                                : AppTheme.success,
                          ),
                          _buildMiniStat(
                            "Avg",
                            cells != null && cells.voltages.isNotEmpty
                                ? avg.toStringAsFixed(3)
                                : "--",
                            "V",
                            Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: math.max(
                      4,
                      cells?.voltages.length ?? 0,
                    ), // Minimum 4 cells
                    itemBuilder: (context, index) {
                      // Check if we have real data for this index
                      if (cells != null && index < cells.voltages.length) {
                        final voltage = cells.voltages[index];
                        // Color grading for voltage
                        Color barColor = AppTheme.systemGreen;
                        if (voltage < 3.0) {
                          barColor = AppTheme.systemRed;
                        } else if (voltage > 4.15) {
                          barColor = AppTheme.systemOrange;
                        }

                        // Normalize for visual bar
                        double normalized = (voltage - 2.8) / (4.2 - 2.8);
                        normalized = normalized.clamp(0.0, 1.0);

                        return GlassContainer(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "#${index + 1}",
                                    style: AppTheme.label.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              // Voltage
                              Center(
                                child: Text(
                                  voltage.toStringAsFixed(3),
                                  style: AppTheme.headline.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: normalized,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation(barColor),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Placeholder Cell
                        return GlassContainer(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "#${index + 1}",
                                    style: AppTheme.label.copyWith(
                                      color: AppTheme.textSecondary.withValues(
                                        alpha: 0.3,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              // Voltage Placeholder
                              Center(
                                child: Text(
                                  "--",
                                  style: AppTheme.headline.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                              // Empty Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: 0,
                                  backgroundColor: Colors.white10,
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: AppTheme.label),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTheme.title2.copyWith(color: color, fontSize: 18),
            ),
            const SizedBox(width: 2),
            Text(unit, style: AppTheme.label.copyWith(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
