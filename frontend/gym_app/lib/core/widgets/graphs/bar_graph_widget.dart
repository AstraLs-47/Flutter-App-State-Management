// Flutter imports:
import 'dart:math' as math;
import 'package:flutter/material.dart';

// Package imports:
import 'package:fl_chart/fl_chart.dart';

// Project imports:
import '../../models/graph_dataset.dart';
import '../../theme/app_colors.dart';

class BarGraphWidget extends StatelessWidget {
  final GraphDataset dataset;
  final Color barColor;
  final double height;

  const BarGraphWidget({
    super.key,
    required this.dataset,
    this.barColor = AppColors.primary,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (dataset.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final maxY = dataset.maxY > 0 ? dataset.maxY * 1.2 : 100.0;
    final chartWidth = math.max(
      dataset.points.length * 72.0,
      MediaQuery.of(context).size.width,
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 18,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value >= 0 && value < dataset.points.length) {
                        final String label =
                            dataset.points[value.toInt()].label ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            width: 60,
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.grey, fontSize: 8),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 5 ? maxY / 5 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              barGroups: dataset.points.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.y,
                      color: barColor,
                      width: 28,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
