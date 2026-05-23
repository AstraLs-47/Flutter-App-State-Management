// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:fl_chart/fl_chart.dart';

// Project imports:
import '../../models/graph_dataset.dart';

class LineGraphWidget extends StatelessWidget {
  final List<GraphDataset> datasets;
  final List<Color>? lineColors;
  final double height;
  final bool showTooltips;
  final double? yInterval;
  final double? fixedMaxY;
  final double? fixedMinY;

  const LineGraphWidget({
    super.key,
    required this.datasets,
    this.lineColors,
    this.height = 220,
    this.showTooltips = true,
    this.yInterval,
    this.fixedMaxY,
    this.fixedMinY,
  });

  /// Returns true when all data points share the same calendar date.
  bool _allSameDay(List<GraphDataset> datasets) {
    final allPoints = datasets.expand((d) => d.points).toList();
    if (allPoints.length <= 1) return true;
    final first = allPoints.first.x;
    return allPoints.every(
      (p) =>
          p.x.year == first.year &&
          p.x.month == first.month &&
          p.x.day == first.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (datasets.isEmpty || datasets.every((d) => d.isEmpty)) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 36, color: Color(0xFFCBD5E1)),
              SizedBox(height: 8),
              Text(
                'No data available yet',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    double maxY = fixedMaxY ?? 0;
    double minY = fixedMinY ?? double.infinity;
    int maxPointsCount = 0;

    if (fixedMaxY == null || fixedMinY == null) {
      for (final dataset in datasets) {
        if (dataset.isNotEmpty) {
          if (dataset.maxY > maxY) maxY = dataset.maxY;
          if (dataset.minY < minY) minY = dataset.minY;
          if (dataset.points.length > maxPointsCount) {
            maxPointsCount = dataset.points.length;
          }
        }
      }
      // Add breathing room: 20% above, 15% below
      maxY = maxY > 0 ? maxY * 1.20 : 140.0;
      minY = minY != double.infinity ? (minY * 0.85).floorToDouble() : 60.0;
    } else {
      for (final dataset in datasets) {
        if (dataset.isNotEmpty && dataset.points.length > maxPointsCount) {
          maxPointsCount = dataset.points.length;
        }
      }
    }

    final bool sameDay = _allSameDay(datasets);

    final lineBarsData = datasets.asMap().entries.map((entry) {
      final index = entry.key;
      final dataset = entry.value;

      final color = lineColors != null && index < lineColors!.length
          ? lineColors![index]
          : (index == 0 ? const Color(0xFF0E6CF2) : const Color(0xFF93C5FD));

      List<FlSpot> spots = dataset.points.asMap().entries.map((pEntry) {
        return FlSpot(pEntry.key.toDouble(), pEntry.value.y);
      }).toList();

      // Handle single-point case: extend to show as a visible line
      if (spots.length == 1) {
        spots = [FlSpot(0, spots[0].y), FlSpot(1, spots[0].y)];
      }

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 2.8,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4.5,
            color: color,
            strokeWidth: 2.5,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.04),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      );
    }).toList();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: showTooltips,
            getTouchedSpotIndicator:
                (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((_) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: const Color(0xFF0E6CF2).withValues(alpha: 0.15),
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 6,
                              color: barData.color ?? const Color(0xFF0E6CF2),
                              strokeWidth: 2.5,
                              strokeColor: Colors.white,
                            ),
                      ),
                    );
                  }).toList();
                },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.white,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipBorder: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                if (touchedBarSpots.isEmpty) return [];

                // IMPORTANT: must return exactly touchedBarSpots.length items.
                return touchedBarSpots.asMap().entries.map((entry) {
                  final i = entry.key;
                  final barSpot = entry.value;
                  final ds = datasets[barSpot.barIndex];

                  final pointIndex = barSpot.x.toInt();
                  final point = (ds.points.length > pointIndex)
                      ? ds.points[pointIndex]
                      : ds.points.isNotEmpty
                      ? ds.points[0]
                      : null;

                  final String xLabel = sameDay
                      ? 'Entry ${pointIndex + 1}'
                      : point != null
                      ? '${point.x.month.toString().padLeft(2, '0')}/${point.x.day.toString().padLeft(2, '0')}'
                      : '';

                  final color =
                      lineColors != null &&
                          barSpot.barIndex < lineColors!.length
                      ? lineColors![barSpot.barIndex]
                      : (barSpot.barIndex == 0
                            ? const Color(0xFF0E6CF2)
                            : const Color(0xFF93C5FD));

                  if (i == 0) {
                    // First spot: show date header + its value
                    return LineTooltipItem(
                      '',
                      const TextStyle(fontSize: 0),
                      children: [
                        TextSpan(
                          text: '$xLabel\n',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                        TextSpan(
                          text: '${ds.title}: ${barSpot.y.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            height: 1.8,
                          ),
                        ),
                      ],
                    );
                  }

                  // Subsequent spots (e.g. diastolic BP): value only
                  return LineTooltipItem(
                    '${ds.title}: ${barSpot.y.toStringAsFixed(1)}',
                    TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                yInterval ??
                ((maxY - minY) > 10 ? ((maxY - minY) / 4).ceilToDouble() : 2),
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFEFF3F8), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _xInterval(maxPointsCount),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0) return const SizedBox.shrink();
                  final ds = datasets.firstWhere(
                    (d) => d.isNotEmpty,
                    orElse: () => datasets[0],
                  );
                  if (ds.isEmpty || idx >= ds.points.length) {
                    return const SizedBox.shrink();
                  }
                  final point = ds.points[idx];
                  final String label = sameDay
                      ? '#${idx + 1}'
                      : '${point.x.month.toString().padLeft(2, '0')}/${point.x.day.toString().padLeft(2, '0')}';

                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      label,
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
                interval:
                    yInterval ??
                    ((maxY - minY) > 10
                        ? ((maxY - minY) / 4).ceilToDouble()
                        : 2),
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  // Skip labels too close to min/max edges
                  if ((value - maxY).abs() < 1 || (value - minY).abs() < 1) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: maxPointsCount <= 1 ? 1 : (maxPointsCount - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: lineBarsData,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Determines a sensible interval for the X axis labels so they don't crowd.
  double _xInterval(int pointCount) {
    if (pointCount <= 5) return 1;
    if (pointCount <= 10) return 2;
    if (pointCount <= 20) return 4;
    return (pointCount / 5).ceilToDouble();
  }
}
