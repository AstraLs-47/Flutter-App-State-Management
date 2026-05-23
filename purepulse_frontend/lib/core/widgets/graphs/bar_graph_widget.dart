// Flutter imports:
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

  /// Width per category slot — gives comfortable spacing between bars.
  static const double _slotWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    if (dataset.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 36, color: Color(0xFFCBD5E1)),
              SizedBox(height: 8),
              Text(
                'No data available',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final maxY = dataset.maxY > 0 ? dataset.maxY * 1.25 : 10.0;
    final int count = dataset.points.length;

    // Chart content width: at least fill parent, or wider when many categories
    final double chartContentWidth = (count * _slotWidth).clamp(
      0.0,
      double.infinity,
    );

    final chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorder: const BorderSide(color: Color(0xFFE2E8F0)),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = dataset.points[group.x].label ?? '';
              return BarTooltipItem(
                '$label\n',
                const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: rod.toY.toStringAsFixed(
                      rod.toY == rod.toY.roundToDouble() ? 0 : 1,
                    ),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= dataset.points.length) {
                  return const SizedBox.shrink();
                }
                final label = dataset.points[idx].label ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    label.length > 9 ? '${label.substring(0, 8)}…' : label,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if ((value - maxY).abs() < 0.5) return const SizedBox.shrink();
                return Text(
                  value == value.roundToDouble()
                      ? value.toInt().toString()
                      : value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
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
          horizontalInterval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFEFF3F8), strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            left: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        barGroups: dataset.points.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.y,
                color: barColor,
                width: 22,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: barColor.withValues(alpha: 0.05),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needsScroll = chartContentWidth > constraints.maxWidth;
          if (!needsScroll) {
            // Fits in the available space — render normally
            return chart;
          }
          // Too many categories — make the chart area horizontally scrollable
          return Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartContentWidth,
                  height: height,
                  child: chart,
                ),
              ),
              // Subtle right-fade hint that the chart is scrollable
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 28,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
