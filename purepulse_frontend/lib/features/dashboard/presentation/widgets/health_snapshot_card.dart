// Flutter imports:
import 'package:flutter/material.dart';
import 'package:gym_app/features/workout/application/workouts_notifier.dart';
import 'package:gym_app/features/progress/application/health_metrics_notifier.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:


class HealthSnapshotCard extends ConsumerWidget {
  const HealthSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthRecords = ref.watch(healthMetricsNotifierProvider).valueOrNull ?? [];
    final workouts = ref.watch(workoutsNotifierProvider).valueOrNull ?? [];

    final latest = healthRecords.isNotEmpty ? healthRecords.first : null;
    final workoutCount = workouts.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HEALTH SNAPSHOT',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSnapshotItem(
                latest != null
                    ? '${latest.systolic.toInt()}/${latest.diastolic.toInt()}'
                    : '0/0',
                'Blood Pressure',
                Icons.bolt,
              ),
              _buildSnapshotItem(
                latest != null
                    ? '${latest.weight.toStringAsFixed(1)} kg'
                    : '0 kg',
                'Weight',
                Icons.balance,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSnapshotItem(
                latest != null
                    ? '${latest.bloodSugar.toInt()} mg/dL'
                    : '0 mg/dL',
                'Blood Sugar',
                Icons.water_drop_outlined,
              ),
              _buildSnapshotItem(
                '$workoutCount',
                'Total Activities',
                Icons.directions_run,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotItem(String value, String label, IconData icon) {
    final parts = value.split(' ');
    final mainValue = parts[0];
    final unit = parts.length > 1 ? parts[1] : '';

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0E6CF2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      mainValue,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
