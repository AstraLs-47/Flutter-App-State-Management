// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../../core/theme/app_colors.dart';

class SimpleLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  const SimpleLineChart({super.key, required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, right: 16.0, bottom: 8.0),
      child: CustomPaint(
        size: const Size(double.infinity, 150),
        painter: _LineChartPainter(data, labels),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  _LineChartPainter(this.data, this.labels);
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const chartLeft = 30.0;
    final chartBottom = size.height - 20.0;
    final chartWidth = size.width - chartLeft;
    final chartHeight = chartBottom;

    final values = data.isEmpty ? [0.0] : data;
    final maxVal = values.reduce((curr, next) => curr > next ? curr : next) > 0
        ? values.reduce((curr, next) => curr > next ? curr : next)
        : 10.0;

    // Draw grid lines and Y-axis labels dynamically based on data
    final yPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    final yStepValue = maxVal / 4;
    for (int i = 0; i < 5; i++) {
      final y = i * (chartHeight / 4);
      final labelValue = (maxVal - (i * yStepValue)).toStringAsFixed(0);
      canvas.drawLine(Offset(chartLeft, y), Offset(size.width, y), yPaint);

      textPainter.text = TextSpan(
        text: labelValue,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw X-axis labels dynamically based on provided labels
    final xStep = labels.length > 1 ? chartWidth / (labels.length - 1) : chartWidth;
    for (int i = 0; i < labels.length; i++) {
      final x = chartLeft + (i * xStep);
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartBottom + 8),
      );
    }

    // Draw chart line
    final path = Path();

    // Using provided data values
    for (int i = 0; i < values.length; i++) {
      final y = chartHeight - (values[i] / maxVal * chartHeight);
      final x = chartLeft + xStep * i;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Draw gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, chartBottom);
    fillPath.lineTo(chartLeft, chartBottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.3),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(chartLeft, 0, chartWidth, chartHeight));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  const DonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 120,
          child: CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _DonutChartPainter(data),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
              AppColors.primary,
              'Cardio',
              '${data['Cardio']?.toInt() ?? 4}',
            ),
            _buildLegendItem(
              const Color(0xFF00A3FF),
              'Strength',
              '${data['Strength']?.toInt() ?? 1}',
            ),
            _buildLegendItem(
              const Color(0xFF90D1FF),
              'Aerobics',
              '${data['Aerobics']?.toInt() ?? 1}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $value',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  _DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2.2;
    final strokeWidth = 24.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = data.values.fold(0.0, (sum, val) => sum + val);
    final cardioVal = data['Cardio'] ?? 0;
    final strengthVal = data['Strength'] ?? 0;
    final aerobicsVal = data['Aerobics'] ?? 0;

    double startAngle = -1.5;

    // Slice 1 (Cardio)
    if (total > 0 && cardioVal > 0) {
      final sweep1 = (cardioVal / total) * 6.28;
      final paint1 = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep1, false, paint1);
      startAngle += sweep1;
    }

    // Slice 2 (Strength)
    if (total > 0 && strengthVal > 0) {
      final sweep2 = (strengthVal / total) * 6.28;
      final paint2 = Paint()
        ..color = const Color(0xFF00A3FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep2, false, paint2);
      startAngle += sweep2;
    }

    // Slice 3 (Aerobics)
    if (total > 0 && aerobicsVal > 0) {
      final sweep3 = (aerobicsVal / total) * 6.28;
      final paint3 = Paint()
        ..color = const Color(0xFF90D1FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep3, false, paint3);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarChartWithAxes extends StatelessWidget {
  final List<double> data;
  const BarChartWithAxes({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, right: 16.0, bottom: 8.0),
      child: CustomPaint(
        size: const Size(double.infinity, 150),
        painter: _BarChartPainter(data),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  _BarChartPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final chartLeft = 20.0;
    final chartBottom = size.height - 20.0;
    final chartWidth = size.width - chartLeft;
    final chartHeight = chartBottom;

    // Draw Y-axis labels and grid lines
    final yLabels = ['15', '10', '5', '0'];
    final yPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = i * (chartHeight / 3);
      canvas.drawLine(Offset(chartLeft, y), Offset(size.width, y), yPaint);

      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw bars and X-axis labels
    final labels = ['Supplement', 'Cardio', 'Supplements', 'Accessories'];

    final maxVal = data.isEmpty
        ? 10.0
        : data.reduce((curr, next) => curr > next ? curr : next);
    final barValues = data.isEmpty
        ? [0.8, 0.8, 0.8, 0.8]
        : data.map((d) => maxVal > 0 ? d / maxVal : 0.0).toList();
    final barWidth = chartWidth / 8;
    final spacing = chartWidth / 4;

    final barPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final x = chartLeft + (spacing / 2) + i * spacing;
      final barHeight = chartHeight * barValues[i];

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          x - barWidth / 2,
          chartHeight - barHeight,
          barWidth,
          barHeight,
        ),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rrect, barPaint);

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartBottom + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
