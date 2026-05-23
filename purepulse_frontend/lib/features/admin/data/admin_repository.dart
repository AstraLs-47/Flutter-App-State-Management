// Project imports:
import '../../progress/data/health_store.dart';

class AdminRepository {
  static final AdminRepository _instance = AdminRepository._internal();
  factory AdminRepository() => _instance;
  AdminRepository._internal();

  final _healthStore = HealthStore();

  // Metrics
  double totalRevenue = 12450.0;
  double revenuePercent = 12.5;
  int totalUsers = 1240;
  double usersPercent = 8.2;
  int totalLogouts = 42;

  void trackLogout() {
    totalLogouts++;
  }

  double get avgBmi {
    if (_healthStore.records.isEmpty) {
      return 22.4;
    }
    return _healthStore.records.map((r) => r.bmi).reduce((a, b) => a + b) /
        _healthStore.records.length;
  }

  double get avgHr => _healthStore.records.isEmpty
      ? 72.0
      : _healthStore.records.map((r) => r.heartRate).reduce((a, b) => a + b) /
            _healthStore.records.length;

  int get totalProducts => products.length;
  double productsPercent = -5.0;

  int get workoutsLogged => activities.length;
  double workoutsPercent = 15.0;

  // Chart Data
  List<double> weeklyEngagementData = [2.0, 6.0, 8.0, 3.0, 4.0, 7.0, 3.0];
  Map<String, double> categoryDistribution = {
    'Cardio': 4.0,
    'Strength': 1.0,
    'Aerobics': 1.0,
  };
  final List<String> activityCategories = [
    'All',
    'Cardio',
    'Strength',
    'Aerobics',
  ];

  List<double> get productsByTypeData {
    int equip = 0, cardio = 0, supp = 0, acc = 0;
    for (var p in products) {
      String cat = (p['category'] ?? '').toUpperCase();
      if (cat.contains('EQUIP')) {
        equip++;
      } else if (cat.contains('CARDIO')) {
        cardio++;
      } else if (cat.contains('SUPP')) {
        supp++;
      } else {
        acc++;
      }
    }
    return [
      equip.toDouble(),
      cardio.toDouble(),
      supp.toDouble(),
      acc.toDouble(),
    ];
  }

  // Lists
  List<Map<String, String>> activities = [
    {
      'title': 'Full Cardio Burn',
      'description': 'Complete cardio session for endurance and fat burn',
      'image': 'assets/full_cardioburn_image.jpg',
      'category': 'Cardio',
    },
    {
      'title': 'Strength Power Set',
      'description': 'Full body strength training with compound movements',
      'image': 'assets/strength_power_set_image.png',
      'category': 'Strength',
    },
    {
      'title': 'Running',
      'description': 'Outdoor or treadmill running',
      'image': 'assets/running_image.jpg',
      'category': 'Cardio',
    },
    {
      'title': 'Dynamic Aerobics',
      'description': 'High-energy aerobic workout for flexibility and stamina',
      'image': 'assets/dynamic_aerobics_image.jpg',
      'category': 'Aerobics',
    },
    {
      'title': 'Jump Rope',
      'description': 'High intensity jump rope',
      'image': 'assets/jumping_image.jpg',
      'category': 'Cardio',
    },
    {
      'title': 'Cycling',
      'description': 'Stationary or outdoor cycling',
      'image': 'assets/cycling_image.png',
      'category': 'Cardio',
    },
  ];

  List<Map<String, String>> products = [
    {
      'title': 'Speed Jump Rope',
      'description': 'A jump rope with a thin PVC plastic cord.',
      'category': 'EQUIPMENT',
      'image': 'assets/speed_jump_rope.png',
    },
    {
      'title': 'Pro Dumbbells 5Kg',
      'description': 'Free-weight dumbbells designed for heavy commercial use.',
      'category': 'EQUIPMENT',
      'image': 'assets/pro_dumbbells.png',
    },
    {
      'title': 'Steel Bottle',
      'description': 'ThermoFlask Stainless Steel Water Bottle',
      'category': 'ACCESSORIES',
      'image': 'assets/steel_bottle.png',
    },
    {
      'title': 'Yoga Mat',
      'description':
          'Premium yoga mats with extra cushioning to support your joints.',
      'category': 'ACCESSORIES',
      'image': 'assets/yoga_mat.png',
    },
    {
      'title': 'Training Gloves',
      'description':
          'Breathable anti Slip Fit gloves for weight lifting gym training',
      'category': 'ACCESSORIES',
      'image': 'assets/training_gloves.png',
    },
    {
      'title': 'Why Isolate Protein',
      'description':
          'High Quality Hydrolyzed & Ultra-Filtered Why Protein Isolate',
      'category': 'SUPPLEMENTS',
      'image': 'assets/protein.png',
    },
  ];

  List<Map<String, String>> announcements = [
    {
      'title': 'Holiday Schedule',
      'description':
          'The gym will be closed on December 25th for Christmas. We wish everyone a Merry Christmas!',
      'date': '2024-12-25',
    },
    {
      'title': 'New Yoga Classes',
      'description':
          'Join us for our new sunrise yoga sessions starting every Monday at 6:00 AM.',
      'date': '2024-03-20',
    },
  ];

  List<Map<String, String>> recentActivities = [
    {'title': 'Full Cardio Burn', 'subtitle': '45 min • 2024-03-15'},
    {'title': 'Strength Power Set', 'subtitle': '60 min • 2024-03-14'},
    {'title': 'Running Session', 'subtitle': '30 min • 2024-03-14'},
  ];

  bool hasNewAnnouncements = true;

  void markAnnouncementsAsViewed() {
    hasNewAnnouncements = false;
  }

  // Actions
  void addActivity(Map<String, String> activity) {
    activities = [activity, ...activities];
    recentActivities = [
      {
        'title': activity['title']!,
        'subtitle': '${activity['category']} • Just now',
      },
      ...recentActivities,
    ];

    String cat = activity['category']!;
    categoryDistribution = Map.from(categoryDistribution)
      ..[cat] = (categoryDistribution[cat] ?? 0) + 1;
    weeklyEngagementData = List.from(weeklyEngagementData)..[6] += 1;
  }

  void removeActivity(Map<String, String> activity) {
    activities = List.from(activities)..remove(activity);
    String cat = activity['category']!;
    categoryDistribution = Map.from(categoryDistribution)
      ..[cat] = (categoryDistribution[cat] ?? 0) - 1;
    if (categoryDistribution[cat]! <= 0) categoryDistribution.remove(cat);
  }

  void updateActivity(
    Map<String, String> oldActivity,
    Map<String, String> newActivity,
  ) {
    int index = activities.indexOf(oldActivity);
    if (index != -1) {
      activities = List.from(activities)..[index] = newActivity;
    }
  }

  void addProduct(Map<String, String> product) {
    products = [product, ...products];
    totalRevenue += 50;
  }

  void updateProduct(int index, Map<String, String> product) {
    products = List.from(products)..[index] = product;
  }

  void removeProduct(Map<String, String> product) {
    products = List.from(products)..remove(product);
    totalRevenue -= 50;
  }

  void addActivityCategory(String category) {
    if (!activityCategories.contains(category)) {
      activityCategories.add(category);
    }
  }

  void addAnnouncement(Map<String, String> announcement) {
    announcements = [announcement, ...announcements];
    hasNewAnnouncements = true;
    recentActivities = [
      {'title': announcement['title']!, 'subtitle': 'News • Just now'},
      ...recentActivities,
    ];
  }

  void updateAnnouncement(int index, Map<String, String> announcement) {
    announcements = List.from(announcements)..[index] = announcement;
  }

  void removeAnnouncement(Map<String, String> announcement) {
    announcements = List.from(announcements)..remove(announcement);
  }
}
