// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Project imports:

import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/activity_model.dart';
import '../../../exercises/application/exercises_notifier.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final Map<String, String> activity;
  final VoidCallback onUpdate;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    required this.onUpdate,
  });

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  late Map<String, String> _activity;

  @override
  void initState() {
    super.initState();
    _activity = Map<String, String>.from(widget.activity);
  }

  // Mock data generator for workout details based on activity title
  Map<String, dynamic> _getWorkoutDetails() {
    final title = _activity['title'] ?? '';

    // Only return mock details for the original 6 preset activities
    final presets = [
      'Full Cardio Burn',
      'Strength Power Set',
      'Running',
      'Dynamic Aerobics',
      'Jump Rope',
      'Cycling',
    ];

    if (!presets.contains(title)) {
      List<Map<String, dynamic>> customSections = [];

      if (_activity['warmup'] != null && _activity['warmup']!.isNotEmpty) {
        customSections.add({
          'title': '🔥 Warm-Up',
          'content': _activity['warmup'],
        });
      }

      if (_activity['mainWorkout'] != null &&
          _activity['mainWorkout']!.isNotEmpty) {
        final category = _activity['category'] ?? 'Exercise';
        String icon = '💪';
        if (category.contains('Cardio')) icon = '🏃';
        if (category.contains('Aerobics')) icon = '🎵';

        customSections.add({
          'title': '$icon Main $category Exercise',
          'content': _activity['mainWorkout'],
        });
      }

      if (_activity['coolDown'] != null && _activity['coolDown']!.isNotEmpty) {
        customSections.add({
          'title': '🧘 Cool Down',
          'content': _activity['coolDown'],
        });
      }

      if (customSections.isEmpty) {
        customSections.add({
          'title': '📋 Exercise Overview',
          'content':
              (_activity['description'] != null &&
                  _activity['description']!.isNotEmpty)
              ? _activity['description']
              : 'No specific workout details provided for this exercise.',
        });
      }

      return {
        'duration':
            (_activity['duration'] != null && _activity['duration']!.isNotEmpty)
            ? _activity['duration']
            : 'N/A',
        'sections': customSections,
        'rest': (_activity['rest'] != null && _activity['rest']!.isNotEmpty)
            ? _activity['rest']
            : 'Standard rest as needed',
      };
    }

    if (title.contains('Strength') || title.contains('Dumbbell')) {
      return {
        'duration': '60 min',
        'sections': [
          {
            'title': '🔥 Warm-Up',
            'items': [
              {
                'title': 'Treadmill Walking',
                'duration': '3-5 min',
                'note': 'Light pace',
              },
              {
                'title': 'Arm Circles',
                'duration': '30 sec each direction',
                'note': '',
              },
              {'title': 'High Knees', 'duration': '20 reps', 'note': ''},
              {
                'title': 'Dynamic Stretching',
                'duration': '2-3 min',
                'note': '',
              },
            ],
          },
          {
            'title': '💪 Main Strength Workout',
            'items': [
              {
                'title': 'Barbell Squat',
                'duration': '8-12 reps x 3 sets',
                'note': 'Keep chest up, push through heels',
              },
              {
                'title': 'Dumbbell Lunges',
                'duration': '8-10 reps each leg x 3 sets',
                'note': '',
              },
              {
                'title': 'Bench Press',
                'duration': '8-12 reps x 3 sets',
                'note': '',
              },
              {
                'title': 'Dumbbell Shoulder Press',
                'duration': '8-12 reps x 3 sets',
                'note': '',
              },
              {
                'title': 'Lat Pulldown',
                'duration': '8-12 reps x 3 sets',
                'note': '',
              },
              {
                'title': 'Seated Cable Row',
                'duration': '8-12 reps x 3 sets',
                'note': '',
              },
              {'title': 'Plank', 'duration': '30-45 sec x 3 sets', 'note': ''},
              {
                'title': 'Hanging Leg Raise',
                'duration': '10-15 reps x 3 sets',
                'note': '',
              },
            ],
          },
          {
            'title': '🧘 Cool Down',
            'items': [
              {
                'title': 'Hamstring Stretch',
                'duration': '20-30 sec',
                'note': '',
              },
              {
                'title': 'Quadriceps Stretch',
                'duration': '20-30 sec each leg',
                'note': '',
              },
              {'title': 'Child\'s Pose', 'duration': '30-60 sec', 'note': ''},
              {
                'title': 'Shoulder Stretch',
                'duration': '20-30 sec',
                'note': '',
              },
            ],
          },
        ],
        'rest':
            'Rest Guidelines: 60-90 sec between sets\n• 1-2 min between exercises',
      };
    } else if (title.contains('Running') || title.contains('Cardio Burn')) {
      return {
        'duration': '45 min',
        'sections': [
          {
            'title': '🔥 Warm-Up',
            'items': [
              {
                'title': 'Treadmill Walking',
                'duration': '3-5 min',
                'note': 'Light pace to get blood flowing',
              },
              {
                'title': 'Arm Circles',
                'duration': '30 sec each direction',
                'note': '',
              },
              {'title': 'High Knees', 'duration': '20 reps', 'note': ''},
            ],
          },
          {
            'title': '🏃 Main Cardio',
            'items': [
              {
                'title': 'Treadmill Run',
                'duration': '15 min',
                'note': 'Moderate pace, 65-75% max HR',
              },
              {'title': 'Jump Rope', 'duration': '3 sets, 3 min', 'note': ''},
              {
                'title': 'Cycling',
                'duration': '10 min',
                'note': 'High resistance intervals',
              },
            ],
          },
          {
            'title': '🧘 Cool Down',
            'items': [
              {'title': 'Walking', 'duration': '3 min', 'note': ''},
              {
                'title': 'Hamstring Stretch',
                'duration': '20-30 sec',
                'note': '',
              },
              {'title': 'Deep Breathing', 'duration': '2 min', 'note': ''},
            ],
          },
        ],
        'rest':
            'Rest Guidelines: 60-90 sec between sets\n• 1-2 min between exercises',
      };
    } else {
      // Preset generic fallback for Cycling, Aerobics, Jump Rope
      return {
        'duration': '40 min',
        'sections': [
          {
            'title': '🔥 Warm-Up',
            'items': [
              {'title': 'March In Place', 'duration': '3 min', 'note': ''},
              {'title': 'Arm Swings', 'duration': '1 min', 'note': ''},
              {
                'title': 'Ankle Rotations',
                'duration': '30 sec each',
                'note': '',
              },
            ],
          },
          {
            'title': '🎵 Main Session',
            'items': [
              {'title': 'Step Touch', 'duration': '3 min', 'note': ''},
              {
                'title': 'Grapevine',
                'duration': 'Alternate sides for 3 min',
                'note': '',
              },
              {'title': 'Box Step', 'duration': '2 min', 'note': ''},
              {
                'title': 'Jumping Jacks',
                'duration': '3 sets x 20 reps',
                'note': '',
              },
              {
                'title': 'Yoga Flow',
                'duration': '10 min',
                'note': 'Sun salutation sequence',
              },
            ],
          },
          {
            'title': '🧘 Cool Down',
            'items': [
              {'title': 'Slow Walking', 'duration': '3 min', 'note': ''},
              {'title': 'Full Body Stretch', 'duration': '5 min', 'note': ''},
              {
                'title': 'Meditation Breathing',
                'duration': '3 min',
                'note': '',
              },
            ],
          },
        ],
        'rest':
            'Rest Guidelines: 60-90 sec between sets\n• 1-2 min between exercises',
      };
    }
  }

  void _showEditDialog(BuildContext context) {
    String newTitle = _activity['title'] ?? '';
    String description = _activity['description'] ?? '';
    String category = _activity['category'] ?? 'Cardio';
    // Ensure current category is valid in list, else default to first
    const dbCats = ['Cardio', 'Strength', 'Aerobics'];
    if (!dbCats.contains(category) && dbCats.isNotEmpty) {
      category = dbCats.first;
    }
    String selectedImg = _activity['image'] ?? 'assets/running_image.jpg';
    String warmup = _activity['warmup'] ?? '';
    String mainWorkout = _activity['mainWorkout'] ?? '';
    String rest = _activity['rest'] ?? '';
    String duration = _activity['duration'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'Edit ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Exercise',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    hintText: 'Exercise name...',
                    initialValue: newTitle,
                    onChanged: (val) => newTitle = val,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: category,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                        ),
                        items: const ['Cardio', 'Strength', 'Aerobics'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        dropdownColor: Colors.white,
                        onChanged: (val) {
                          if (val != null) setDialogState(() => category = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    hintText: 'Description...',
                    initialValue: description,
                    onChanged: (val) => description = val,
                    maxLines: 2,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    hintText: 'Duration (e.g., 45 min)...',
                    initialValue: duration,
                    onChanged: (val) => duration = val,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    hintText: 'Warm-up details...',
                    initialValue: warmup,
                    onChanged: (val) => warmup = val,
                    maxLines: 3,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    hintText: 'Main Exercise (Category) details...',
                    initialValue: mainWorkout,
                    onChanged: (val) => mainWorkout = val,
                    maxLines: 4,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    hintText: 'Rest guidelines...',
                    initialValue: rest,
                    onChanged: (val) => rest = val,
                    maxLines: 2,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      _pickImage(context, (path) {
                        setDialogState(() => selectedImg = path);
                      });
                    },
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: selectedImg.startsWith('assets/')
                              ? AssetImage(selectedImg) as ImageProvider
                              : ((kIsWeb ||
                                            selectedImg.startsWith('http') ||
                                            selectedImg.startsWith('blob:'))
                                        ? NetworkImage(selectedImg)
                                        : FileImage(File(selectedImg)))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final updatedActivity = {
                        'id': _activity['id']!,
                        'title': newTitle,
                        'description': description,
                        'category': category,
                        'image': selectedImg,
                        'warmup': warmup,
                        'mainWorkout': mainWorkout,
                        'rest': rest,
                        'duration': duration,
                      };
                      final activityModel = Activity(
                        id: _activity['id']!,
                        title: newTitle,
                        description: description,
                        category: category,
                        image: selectedImg,
                        warmup: warmup,
                        mainWorkout: mainWorkout,
                        rest: rest,
                        duration: duration,
                      );
                      ref
                          .read(activitiesNotifierProvider.notifier)
                          .updateActivity(activityModel);
                      setState(() {
                        _activity = updatedActivity;
                      });
                      widget.onUpdate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exercise updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(ctx); // Only pop the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hintText,
    required String initialValue,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    double fontSize = 13,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      maxLines: maxLines,
      style: TextStyle(fontSize: fontSize, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey, fontSize: fontSize),
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Remove Exercise',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to remove this exercise from the activity list?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(activitiesNotifierProvider.notifier)
                            .delete(_activity['id']!);
                        widget.onUpdate();
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F0F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickImage(BuildContext context, Function(String) onPicked) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      onPicked(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _activity['title'] ?? 'Activity';
    final details = _getWorkoutDetails();
    final sections = details['sections'] as List<Map<String, dynamic>>;

    // Check if alignment should be topCenter for specific images
    final Alignment imageAlignment =
        (title == 'Jump Rope' ||
            title == 'Dynamic Aerobics' ||
            title == 'Cycling')
        ? Alignment.topCenter
        : (title.toLowerCase().contains('running') ||
              title.toLowerCase().contains('cardio burn'))
        ? const Alignment(0, -0.1)
        : Alignment.center;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: 70,
            leading: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: _activity['title'] ?? 'activity',
                child:
                    (_activity['image'] != null &&
                        _activity['image']!.isNotEmpty)
                    ? (_activity['image']!.startsWith('assets/')
                          ? Image.asset(
                              _activity['image']!,
                              fit: BoxFit.cover,
                              alignment: imageAlignment,
                            )
                          : ((kIsWeb ||
                                    _activity['image']!.startsWith('http') ||
                                    _activity['image']!.startsWith('blob:'))
                                ? Image.network(
                                    _activity['image']!,
                                    fit: BoxFit.cover,
                                    alignment: imageAlignment,
                                  )
                                : Image.file(
                                    File(_activity['image']!),
                                    fit: BoxFit.cover,
                                    alignment: imageAlignment,
                                  )))
                    : Container(color: Colors.grey),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _activity['category']?.toUpperCase() ?? 'CARDIO',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (details['duration'] != null) ...[
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              details['duration'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _showEditDialog(context),
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () => _showDeleteDialog(context),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title and Description
                  Text(
                    _activity['title'] ?? 'Activity',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activity['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Workout Sections
                  ...sections.map((section) => _buildSection(section)),

                  // Rest Guidelines
                  if (details['rest'] != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.pause_circle_outline,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              details['rest'] as String,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 48), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final String title = section['title'];

    // Check if it's custom content (String) or preset items (List)
    final dynamic content = section['content'];
    final List<Map<String, String>>? items = section['items'] != null
        ? (section['items'] as List).cast<Map<String, String>>()
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: items != null
                ? Column(
                    children: items.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Map<String, String> item = entry.value;
                      bool isLast = idx == items.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 10,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['duration']!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item['note']!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item['note']!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Text(
                    content as String,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
