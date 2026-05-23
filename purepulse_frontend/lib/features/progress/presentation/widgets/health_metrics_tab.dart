// Flutter imports:
import 'package:flutter/material.dart';
import 'package:gym_app/features/progress/application/health_metrics_notifier.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../../core/utils/graph_transformers.dart';
import '../../../../core/widgets/graphs/graph_container.dart';
import '../../../../core/widgets/graphs/line_graph_widget.dart';

import '../../domain/health_record_model.dart';

class HealthMetricsTab extends ConsumerStatefulWidget {
  const HealthMetricsTab({super.key});

  @override
  ConsumerState<HealthMetricsTab> createState() => _HealthMetricsTabState();
}

class _HealthMetricsTabState extends ConsumerState<HealthMetricsTab> {
  int _selectedMetricIndex = 0; // Default to BMI

  String get _selectedMetricLabel {
    switch (_selectedMetricIndex) {
      case 0:
        return 'BMI';
      case 1:
        return 'Heart Rate';
      case 2:
        return 'BP';
      default:
        return 'BMI';
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthRecordsAsync = ref.watch(healthMetricsNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: healthRecordsAsync.when(
        data: (records) {
          final latest = records.isNotEmpty ? records.first : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricToggle(),
              const SizedBox(height: 24),
              _buildCurrentMetricHeader(latest),
              const SizedBox(height: 16),
              _buildGraphContainer(records),
              const SizedBox(height: 32),
              _buildMetricsGrid(latest),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMetricToggle() {
    return Row(
      children: [
        _buildToggleItem('BMI', 0, Icons.grid_view),
        const SizedBox(width: 12),
        _buildToggleItem('Heart Rate', 1, Icons.favorite_border),
        const SizedBox(width: 12),
        _buildToggleItem('BP', 2, Icons.bolt),
      ],
    );
  }

  Widget _buildToggleItem(String label, int index, IconData icon) {
    final isSelected = _selectedMetricIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMetricIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E6CF2) : const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMetricHeader(HealthRecord? latest) {
    if (latest == null && _selectedMetricIndex == 0) {
      return const SizedBox.shrink();
    }

    if (_selectedMetricIndex == 0 && latest != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT BMI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                latest.bmi.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                latest.bmiCategory,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: latest.bmiColor,
                ),
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGraphContainer(List<HealthRecord> records) {
    if (records.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: const Center(
          child: Text(
            'No data recorded yet.\nAdd your health metrics to see progress.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      );
    }

    final datasets = GraphTransformers.healthRecordsToDatasets(
      records,
      _selectedMetricLabel,
    );

    double? interval;
    switch (_selectedMetricLabel) {
      case 'BMI':
        interval = 7.0;
        break;
      case 'Heart Rate':
        interval = 20.0;
        break;
      case 'BP':
        interval = 30.0;
        break;
    }

    return GraphContainer(
      title: '',
      child: LineGraphWidget(
        datasets: datasets,
        height: 200,
        showTooltips: true,
        yInterval: interval,
      ),
    );
  }

  Widget _buildMetricsGrid(HealthRecord? latest) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          latest != null
              ? '${latest.systolic.toInt()}/${latest.diastolic.toInt()}'
              : '--',
          'mmHg',
          'Blood Pressure',
          Icons.bolt,
        ),
        _buildMetricCard(
          latest != null ? latest.heartRate.toInt().toString() : '--',
          'BPM',
          'Heart Rate',
          Icons.favorite_border,
        ),
        _buildMetricCard(
          latest != null ? latest.bloodSugar.toInt().toString() : '--',
          'mg/dL',
          'Blood Sugar',
          Icons.water_drop_outlined,
        ),
        _buildMetricCard(
          latest != null ? latest.weight.toStringAsFixed(1) : '--',
          'kg',
          'Weight',
          Icons.balance,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String value,
    String unit,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0E6CF2)),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
