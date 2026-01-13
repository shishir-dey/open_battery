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
    final isDark = AppTheme.isDark(context);

    return Consumer<BmsProvider>(
      builder: (context, provider, child) {
        debugPrint("Dashboard: Build called, baseInfo: ${provider.baseInfo}");
        final info = provider.baseInfo;

        return Scaffold(
          backgroundColor: AppTheme.getBackground(context),
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
                      color: AppTheme.getPrimary(
                        context,
                      ).withValues(alpha: 0.2),
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
                      color: AppTheme.getSuccess(
                        context,
                      ).withValues(alpha: 0.15),
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
                              style: AppTheme.title2Style(context),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.grid_view,
                                    color: AppTheme.getTextPrimary(context),
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CellsScreen(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.power_settings_new,
                                    color: AppTheme.getError(context),
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
                                  SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: CircularProgressIndicator(
                                      value: 1.0,
                                      color: isDark
                                          ? const Color(0xFF1C1C1E)
                                          : const Color(0xFFE5E5EA),
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
                                              context,
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
                                        style: AppTheme.largeValueStyle(context)
                                            .copyWith(
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
                                            context,
                                            info,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              context,
                                              info,
                                            ).withValues(alpha: 0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(info),
                                          style: AppTheme.labelStyle(context)
                                              .copyWith(
                                                color: _getStatusColor(
                                                  context,
                                                  info,
                                                ),
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
                                  context,
                                  "Power",
                                  info != null
                                      ? "${(info.totalVoltage * info.current).abs().toStringAsFixed(0)}W"
                                      : "--W",
                                  AppTheme.getTextPrimary(context),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppTheme.getDividerColor(context),
                                ),
                                _buildQuickInfo(
                                  context,
                                  "Current",
                                  info != null
                                      ? "${info.current.toStringAsFixed(1)}A"
                                      : "--A",
                                  info != null
                                      ? (info.current > 0
                                            ? AppTheme.getSuccess(context)
                                            : (info.current < 0
                                                  ? AppTheme.getError(context)
                                                  : AppTheme.getTextPrimary(
                                                      context,
                                                    )))
                                      : AppTheme.getTextPrimary(context),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppTheme.getDividerColor(context),
                                ),
                                _buildQuickInfo(
                                  context,
                                  "Voltage",
                                  info != null
                                      ? "${info.totalVoltage.toStringAsFixed(1)}V"
                                      : "--V",
                                  AppTheme.getPrimary(context),
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
                            context,
                            "Rem. Cap",
                            info != null
                                ? "${info.remainingCapacity.toStringAsFixed(2)}Ah"
                                : "--Ah",
                            Icons.battery_full,
                            AppTheme.getSuccess(context),
                          ),
                          _buildStatCard(
                            context,
                            "Temp",
                            (info != null && info.temperatures.isNotEmpty)
                                ? "${info.temperatures.first.toStringAsFixed(1)}°C"
                                : "--",
                            Icons.thermostat,
                            AppTheme.getWarning(context),
                          ),
                          _buildStatCard(
                            context,
                            "Cycles",
                            info != null ? "${info.cycleCount}" : "--",
                            Icons.refresh,
                            Colors.blueGrey,
                          ),
                          _buildStatCard(
                            context,
                            "SoH",
                            "${100}%", // Placeholder for now
                            Icons.health_and_safety,
                            AppTheme.getPrimary(context),
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

  Color _getSocColor(BuildContext context, int rsoc) {
    if (rsoc > 20) return AppTheme.getSuccess(context);
    return AppTheme.getError(context);
  }

  Color _getStatusColor(BuildContext context, dynamic info) {
    if (info == null) return AppTheme.getPrimary(context);
    if (info.isCharging) return AppTheme.getSuccess(context);
    if (info.isDischarging) return AppTheme.getError(context);
    return AppTheme.getTextSecondary(context);
  }

  String _getStatusText(dynamic info) {
    if (info == null) return "CONNECTING...";
    if (info.isCharging) return "CHARGING";
    if (info.isDischarging) return "DISCHARGING";
    return "IDLE";
  }

  Widget _buildQuickInfo(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.title2Style(
            context,
          ).copyWith(color: color, fontSize: 18),
        ),
        Text(label, style: AppTheme.labelStyle(context).copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
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
              Text(title, style: AppTheme.labelStyle(context)),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppTheme.largeValueStyle(context).copyWith(fontSize: 28),
          ),
        ],
      ),
    );
  }
}
