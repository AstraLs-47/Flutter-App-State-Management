// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../../core/models/graph_dataset.dart';
import '../../../../core/models/graph_point.dart';
import '../../../../core/widgets/graphs/graph_container.dart';
import '../../../../core/widgets/graphs/line_graph_widget.dart';
import '../../../progress/application/health_metrics_notifier.dart';

class BPSnapshotGraph extends ConsumerWidget {
  const BPSnapshotGraph({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthMetricsNotifierProvider);
    final records = healthAsync.valueOrNull ?? [];

    if (records.isEmpty) {
      return const SizedBox.shrink();
    }

    // Convert records to GraphDatasets (reverse for chronological order)
    final chronologicalRecords = records.reversed.toList();

    final systolicPoints = chronologicalRecords
        .map((r) => GraphPoint(x: r.date, y: r.systolic))
        .toList();
    final diastolicPoints = chronologicalRecords
        .map((r) => GraphPoint(x: r.date, y: r.diastolic))
        .toList();

    final datasets = [
      GraphDataset(title: 'Systolic', points: systolicPoints),
      GraphDataset(title: 'Diastolic', points: diastolicPoints),
    ];

    return GraphContainer(
      title: 'BLOOD PRESSURE TREND',
      child: LineGraphWidget(
        datasets: datasets,
        height: 180,
        fixedMaxY: 140,
        fixedMinY: 60,
        yInterval: 20,
      ),
    );
  }
}
