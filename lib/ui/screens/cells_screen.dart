/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/ui/screens/cells_screen.dart
 * Description: Screen widget for displaying individual cell voltages in a grid layout with statistics.
 * Author: Shishir Dey
 * License: MIT
 */

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
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
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
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppTheme.getTextPrimary(context),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          "Cells",
                          style: AppTheme.title2Style(context),
                        ),
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
                            context,
                            "Max",
                            cells != null && cells.voltages.isNotEmpty
                                ? maxV.toStringAsFixed(3)
                                : "--",
                            "V",
                            AppTheme.getError(context),
                          ),
                          _buildMiniStat(
                            context,
                            "Min",
                            cells != null && cells.voltages.isNotEmpty
                                ? minV.toStringAsFixed(3)
                                : "--",
                            "V",
                            AppTheme.getPrimary(context),
                          ),
                          _buildMiniStat(
                            context,
                            "Diff",
                            cells != null && cells.voltages.isNotEmpty
                                ? (diff * 1000).toStringAsFixed(0)
                                : "--",
                            "mV",
                            (cells != null && diff > 0.02)
                                ? AppTheme.getWarning(context)
                                : AppTheme.getSuccess(context),
                          ),
                          _buildMiniStat(
                            context,
                            "Avg",
                            cells != null && cells.voltages.isNotEmpty
                                ? avg.toStringAsFixed(3)
                                : "--",
                            "V",
                            AppTheme.getTextPrimary(context),
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
                        Color barColor = AppTheme.getSuccess(context);
                        if (voltage < 3.0) {
                          barColor = AppTheme.getError(context);
                        } else if (voltage > 4.15) {
                          barColor = AppTheme.getWarning(context);
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
                                    style: AppTheme.labelStyle(context)
                                        .copyWith(
                                          color: AppTheme.getTextSecondary(
                                            context,
                                          ),
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
                                  style: AppTheme.headlineStyle(context)
                                      .copyWith(
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
                                  backgroundColor: isDark
                                      ? Colors.white10
                                      : Colors.black12,
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
                                    style: AppTheme.labelStyle(context)
                                        .copyWith(
                                          color: AppTheme.getTextSecondary(
                                            context,
                                          ).withValues(alpha: 0.3),
                                          fontSize: 10,
                                        ),
                                  ),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              // Voltage Placeholder
                              Center(
                                child: Text(
                                  "--",
                                  style: AppTheme.headlineStyle(context)
                                      .copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black26,
                                      ),
                                ),
                              ),
                              // Empty Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: 0,
                                  backgroundColor: isDark
                                      ? Colors.white10
                                      : Colors.black12,
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

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(label, style: AppTheme.labelStyle(context)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTheme.title2Style(
                context,
              ).copyWith(color: color, fontSize: 18),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: AppTheme.labelStyle(context).copyWith(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
