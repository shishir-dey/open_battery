import 'package:flutter/material.dart';
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
            if (cells == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.systemBlue),
                    const SizedBox(height: 16),
                    Text(
                      "Waiting for cell data...",
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Calculate stats
            double maxV = cells.voltages.isNotEmpty
                ? cells.voltages.reduce(
                    (curr, next) => curr > next ? curr : next,
                  )
                : 0;
            double minV = cells.voltages.isNotEmpty
                ? cells.voltages.reduce(
                    (curr, next) => curr < next ? curr : next,
                  )
                : 0;
            double diff = maxV - minV;
            double avg = cells.voltages.isNotEmpty
                ? (cells.voltages.fold(0.0, (p, c) => p + c) /
                      cells.voltages.length)
                : 0;

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
                      Expanded(
                        child: Text("Cells", style: AppTheme.largeTitle),
                      ),
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
                            maxV.toStringAsFixed(3),
                            "V",
                            AppTheme.systemRed,
                          ),
                          _buildMiniStat(
                            "Min",
                            minV.toStringAsFixed(3),
                            "V",
                            AppTheme.systemBlue,
                          ),
                          _buildMiniStat(
                            "Diff",
                            (diff * 1000).toStringAsFixed(0),
                            "mV",
                            diff > 0.02
                                ? AppTheme.warning
                                : AppTheme.success, // Warning if diff > 20mV
                          ),
                          _buildMiniStat(
                            "Avg",
                            avg.toStringAsFixed(3),
                            "V",
                            Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: cells.voltages.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final voltage = cells.voltages[index];
                      // Color grading for voltage
                      Color barColor = AppTheme.systemGreen;
                      if (voltage < 3.0) {
                        barColor = AppTheme.systemRed;
                      } else if (voltage > 4.15) {
                        barColor = AppTheme.systemOrange;
                      }

                      // Normalize for visual bar: assume range 3.0V to 4.2V generally useful
                      // Clamping for display purposes
                      double normalized = (voltage - 2.8) / (4.2 - 2.8);
                      normalized = normalized.clamp(0.0, 1.0);

                      return GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Cell Number
                            SizedBox(
                              width: 30,
                              child: Text(
                                "${index + 1}",
                                style: AppTheme.headline.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Visual Bar
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Voltage Text
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Voltage",
                                        style: AppTheme.label.copyWith(
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        "${voltage.toStringAsFixed(3)} V",
                                        style: AppTheme.headline.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Custom Bar
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Stack(
                                        children: [
                                          // Track
                                          Container(
                                            height: 6,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          // Fill
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 500,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            height: 6,
                                            width:
                                                constraints.maxWidth *
                                                normalized,
                                            decoration: BoxDecoration(
                                              color: barColor,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: barColor.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                  blurRadius: 6,
                                                  spreadRadius: -1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
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
