/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/ui/screens/dashboard_screen.dart
 * Description: Main dashboard screen displaying BMS data including SOC, voltage, current, and other metrics.
 * Author: Shishir Dey
 * License: MIT
 */

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bms_provider.dart';
import 'cells_screen.dart';
import 'scan_screen.dart';
import '../theme.dart';
import '../widgets/glass_container.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BmsProvider>(
      builder: (context, provider, child) {
        final info = provider.baseInfo;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ambient glow
              Positioned(
                top: -100,
                left: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.systemBlue.withValues(alpha: 0.2),
                      backgroundBlendMode: BlendMode.screen,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                right: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.systemGreen.withValues(alpha: 0.15),
                      backgroundBlendMode: BlendMode.screen,
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider.device?.platformName ?? "BMS",
                              style: AppTheme.title2,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.grid_view,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CellsScreen(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.power_settings_new,
                                    color: AppTheme.systemRed,
                                  ),
                                  onPressed: () {
                                    provider.disconnect();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ScanScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Hero SOC Ring
                      const Spacer(),
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 180,
                              width: 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // BG Ring
                                  const SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: CircularProgressIndicator(
                                      value: 1.0,
                                      color: Color(0xFF1C1C1E),
                                      strokeWidth: 16,
                                    ),
                                  ),
                                  // Value Ring
                                  SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(
                                        begin: 0,
                                        end: (info?.rsoc ?? 0) / 100.0,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                      curve: Curves.easeOutQuart,
                                      builder: (context, value, _) =>
                                          CircularProgressIndicator(
                                            value: value,
                                            color: _getSocColor(
                                              info?.rsoc ?? 0,
                                            ),
                                            strokeWidth: 16,
                                            strokeCap: StrokeCap.round,
                                          ),
                                    ),
                                  ),
                                  // Text
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        info != null ? "${info.rsoc}%" : "--%",
                                        style: AppTheme.largeValue.copyWith(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w200,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            info,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              info,
                                            ).withValues(alpha: 0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(info),
                                          style: AppTheme.label.copyWith(
                                            color: _getStatusColor(info),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Power metric
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildQuickInfo(
                                  "Power",
                                  info != null
                                      ? "${(info.totalVoltage * info.current).abs().toStringAsFixed(0)}W"
                                      : "--W",
                                  Colors.white,
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white10,
                                ),
                                _buildQuickInfo(
                                  "Current",
                                  info != null
                                      ? "${info.current.toStringAsFixed(1)}A"
                                      : "--A",
                                  info != null
                                      ? (info.current > 0
                                            ? AppTheme.success
                                            : (info.current < 0
                                                  ? AppTheme.error
                                                  : Colors.white))
                                      : Colors.white,
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white10,
                                ),
                                _buildQuickInfo(
                                  "Voltage",
                                  info != null
                                      ? "${info.totalVoltage.toStringAsFixed(1)}V"
                                      : "--V",
                                  AppTheme.systemBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _buildStatCard(
                            "Rem. Cap",
                            info != null
                                ? "${info.remainingCapacity.toStringAsFixed(2)}Ah"
                                : "--Ah",
                            Icons.battery_full,
                            AppTheme.systemGreen,
                          ),
                          _buildStatCard(
                            "Temp",
                            (info != null && info.temperatures.isNotEmpty)
                                ? "${info.temperatures.first.toStringAsFixed(1)}°C"
                                : "--",
                            Icons.thermostat,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            "Cycles",
                            info != null ? "${info.cycleCount}" : "--",
                            Icons.refresh,
                            Colors.blueGrey,
                          ),
                          _buildStatCard(
                            "SoH",
                            "${100}%", // Placeholder for now
                            Icons.health_and_safety,
                            AppTheme.systemBlue,
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getSocColor(int rsoc) {
    if (rsoc > 20) return AppTheme.success;
    return AppTheme.error;
  }

  Color _getStatusColor(dynamic info) {
    if (info == null) return AppTheme.systemBlue;
    if (info.isCharging) return AppTheme.success;
    if (info.isDischarging) return AppTheme.error;
    return AppTheme.textSecondary;
  }

  String _getStatusText(dynamic info) {
    if (info == null) return "CONNECTING...";
    if (info.isCharging) return "CHARGING";
    if (info.isDischarging) return "DISCHARGING";
    return "IDLE";
  }

  Widget _buildQuickInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.title2.copyWith(color: color, fontSize: 18),
        ),
        Text(label, style: AppTheme.label.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color accent,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.label),
            ],
          ),
          const Spacer(),
          Text(value, style: AppTheme.largeValue.copyWith(fontSize: 28)),
        ],
      ),
    );
  }
}
