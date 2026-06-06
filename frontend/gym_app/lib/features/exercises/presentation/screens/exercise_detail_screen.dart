// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:

// Project imports:
import '../../../admin/presentation/screens/activity_detail_screen.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Map<String, String> exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});
  @override
  Widget build(BuildContext context) {
    // Delegate to the admin ActivityDetailScreen UI but hide admin actions (edit/delete)
    return ActivityDetailScreen(
      activity: exercise,
      onUpdate: () {},
      showActions: false,
    );
  }
}
