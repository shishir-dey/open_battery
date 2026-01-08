import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bms_provider.dart';
import 'cells_screen.dart';
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
                child: info == null
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.device?.platformName ?? "BMS",
                                    style: AppTheme.largeTitle,
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
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Hero SOC Ring
                            GlassContainer(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 220,
                                    width: 220,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // BG Ring
                                        const SizedBox(
                                          width: 220,
                                          height: 220,
                                          child: CircularProgressIndicator(
                                            value: 1.0,
                                            color: Color(0xFF1C1C1E),
                                            strokeWidth: 24,
                                          ),
                                        ),
                                        // Value Ring
                                        SizedBox(
                                          width: 220,
                                          height: 220,
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween(
                                              begin: 0,
                                              end: info.rsoc / 100.0,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 1500,
                                            ),
                                            curve: Curves.easeOutQuart,
                                            builder: (context, value, _) =>
                                                CircularProgressIndicator(
                                                  value: value,
                                                  color: _getSocColor(
                                                    info.rsoc,
                                                  ),
                                                  strokeWidth: 24,
                                                  strokeCap: StrokeCap.round,
                                                ),
                                          ),
                                        ),
                                        // Text
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "${info.rsoc}%",
                                              style: AppTheme.largeValue
                                                  .copyWith(
                                                    fontSize: 52,
                                                    fontWeight: FontWeight.w200,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  info,
                                                ).withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildQuickInfo(
                                        "Power",
                                        "${(info.totalVoltage * info.current).abs().toStringAsFixed(0)}W",
                                        Colors.white,
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.white10,
                                      ),
                                      _buildQuickInfo(
                                        "Current",
                                        "${info.current.toStringAsFixed(1)}A",
                                        info.current > 0
                                            ? AppTheme.success
                                            : (info.current < 0
                                                  ? AppTheme.error
                                                  : Colors.white),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.white10,
                                      ),
                                      _buildQuickInfo(
                                        "Voltage",
                                        "${info.totalVoltage.toStringAsFixed(1)}V",
                                        AppTheme.systemBlue,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Stats Grid
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.4,
                                children: [
                                  _buildStatCard(
                                    "Rem. Cap",
                                    "${info.remainingCapacity.toStringAsFixed(2)}Ah",
                                    Icons.battery_full,
                                    AppTheme.systemGreen,
                                  ),
                                  _buildStatCard(
                                    "Temp",
                                    info.temperatures.isNotEmpty
                                        ? "${info.temperatures.first}°C"
                                        : "--",
                                    Icons.thermostat,
                                    Colors.orange,
                                  ),
                                  _buildStatCard(
                                    "Cycles",
                                    "${info.cycleCount}",
                                    Icons.refresh,
                                    Colors.blueGrey,
                                  ),
                                  _buildStatCard(
                                    "SoH",
                                    "${100}%",
                                    Icons.health_and_safety,
                                    AppTheme.systemBlue,
                                  ),
                                ],
                              ),
                            ),
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
    if (info.isCharging) return AppTheme.success;
    if (info.isDischarging) return AppTheme.error;
    return AppTheme.textSecondary;
  }

  String _getStatusText(dynamic info) {
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
