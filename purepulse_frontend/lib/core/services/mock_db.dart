// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import '../../features/progress/data/health_store.dart';

class MockDB {
  static final MockDB _instance = MockDB._internal();
  factory MockDB() => _instance;
  MockDB._internal();

  final _healthStore = HealthStore();

  static const String _keyProducts = 'gym_products';
  static const String _keyActivities = 'gym_activities';
  static const String _keyAnnouncements = 'gym_announcements';
  static const String _keyCategories = 'gym_categories';

  bool _initialized = false;
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    final prodStr = prefs.getString(_keyProducts);
    if (prodStr != null) {
      products = List<Map<String, String>>.from(
        json.decode(prodStr).map((x) => Map<String, String>.from(x)),
      );
    }

    final actStr = prefs.getString(_keyActivities);
    if (actStr != null) {
      activities = List<Map<String, String>>.from(
        json.decode(actStr).map((x) => Map<String, String>.from(x)),
      );
    }

    final annStr = prefs.getString(_keyAnnouncements);
    if (annStr != null) {
      announcements = List<Map<String, String>>.from(
        json.decode(annStr).map((x) => Map<String, String>.from(x)),
      );
    }

    final catStr = prefs.getString(_keyCategories);
    if (catStr != null) {
      categories = List<String>.from(json.decode(catStr));
    }
    _initialized = true;
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProducts, json.encode(products));
    await prefs.setString(_keyActivities, json.encode(activities));
    await prefs.setString(_keyAnnouncements, json.encode(announcements));
    await prefs.setString(_keyCategories, json.encode(categories));
  }

  // Metrics (Static)
  double totalRevenue = 12450.0;
  int totalLogouts = 42;

  // Lists (Source of Truth)
  List<String> categories = ['Cardio', 'Strength', 'Aerobics'];
  List<String> productCategories = [
    'Equipment',
    'Cardio',
    'Accessories',
    'Supplements',
  ];

  List<Map<String, String>> activities = [
    {
      'id': '1',
      'title': 'Full Cardio Burn',
      'description': 'Complete cardio session for endurance and fat burn',
      'image': 'assets/full_cardioburn_image.jpg',
      'category': 'Cardio',
    },
    {
      'id': '2',
      'title': 'Strength Power Set',
      'description': 'Full body strength training with compound movements',
      'image': 'assets/strength_power_set_image.png',
      'category': 'Strength',
    },
    {
      'id': '3',
      'title': 'Running',
      'description': 'Outdoor or treadmill running',
      'image': 'assets/running_image.jpg',
      'category': 'Cardio',
    },
    {
      'id': '4',
      'title': 'Dynamic Aerobics',
      'description': 'High-energy aerobic workout for flexibility and stamina',
      'image': 'assets/dynamic_aerobics_image.jpg',
      'category': 'Aerobics',
    },
    {
      'id': '5',
      'title': 'Jump Rope',
      'description': 'High intensity jump rope',
      'image': 'assets/jumping_image.jpg',
      'category': 'Cardio',
    },
    {
      'id': '6',
      'title': 'Cycling',
      'description': 'Stationary or outdoor cycling',
      'image': 'assets/cycling_image.png',
      'category': 'Cardio',
    },
  ];

  List<Map<String, String>> products = [
    {
      'id': 'p1',
      'title': 'Speed Jump Rope',
      'description': 'A jump rope with a thin PVC plastic cord.',
      'category': 'EQUIPMENT',
      'image': 'assets/speed_jump_rope.png',
    },
    {
      'id': 'p2',
      'title': 'Pro Dumbbells 5Kg',
      'description': 'Free-weight dumbbells designed for heavy commercial use.',
      'category': 'EQUIPMENT',
      'image': 'assets/pro_dumbbells.png',
    },
    {
      'id': 'p3',
      'title': 'Steel Bottle',
      'description': 'ThermoFlask Stainless Steel Water Bottle',
      'category': 'ACCESSORIES',
      'image': 'assets/steel_bottle.png',
    },
    {
      'id': 'p4',
      'title': 'Yoga Mat',
      'description':
          'Premium yoga mats with extra cushioning to support your joints.',
      'category': 'ACCESSORIES',
      'image': 'assets/yoga_mat.png',
    },
    {
      'id': 'p5',
      'title': 'Training Gloves',
      'description':
          'Breathable anti Slip Fit gloves for weight lifting gym training',
      'category': 'ACCESSORIES',
      'image': 'assets/training_gloves.png',
    },
    {
      'id': 'p6',
      'title': 'Whey Isolate Protein', // Fixed typo
      'description':
          'High Quality Hydrolyzed & Ultra-Filtered Whey Protein Isolate',
      'category': 'SUPPLEMENTS',
      'image': 'assets/protein.png',
    },
  ];

  List<Map<String, String>> announcements = [
    {
      'id': 'a1',
      'title': 'Holiday Schedule',
      'description': 'The gym will be closed on December 25th for Christmas.',
      'date': '2024-12-25',
    },
    {
      'id': 'a2',
      'title': 'New Yoga Classes',
      'description':
          'Join us for our new sunrise yoga sessions starting every Monday.',
      'date': '2024-03-20',
    },
  ];

  bool _hasNewAnnouncements = true;
  bool get hasNewAnnouncements => _hasNewAnnouncements;
  void markAnnouncementsAsViewed() {
    _hasNewAnnouncements = false;
  }

  List<Map<String, String>> get recentActivities {
    List<Map<String, String>> items = [];

    // Add latest 2 announcements
    for (var i = 0; i < announcements.length && i < 2; i++) {
      items.add({
        'title': announcements[i]['title'] ?? 'New Announcement',
        'subtitle': 'News • ${announcements[i]['date']}',
      });
    }

    // Add latest 2 activities
    for (var i = 0; i < activities.length && i < 2; i++) {
      items.add({
        'title': activities[i]['title'] ?? 'New Activity',
        'subtitle': '${activities[i]['category']} • Recently added',
      });
    }

    // Add latest 2 products
    for (var i = 0; i < products.length && i < 2; i++) {
      items.add({
        'title': products[i]['title'] ?? 'New Product',
        'subtitle': '${products[i]['category']} • Stock updated',
      });
    }

    if (items.isEmpty) {
      items.add({
        'title': 'System Ready',
        'subtitle': 'No recent actions recorded',
      });
    }

    return items;
  }

  // Logic for calculations
  int getTotalProducts() => products.length;

  List<double> get weeklyEngagementData {
    // Return a list that reflects the actual counts to show "activity"
    double base = 30.0;
    return [
      base + activities.length,
      base + products.length + 5,
      base + announcements.length + 10,
      base + (activities.length * 1.5),
      base + (products.length * 1.2),
      base + (announcements.length * 2.0),
      base + activities.length + products.length,
    ];
  }

  double calculateAvgBMI() {
    if (_healthStore.records.isEmpty) return 0.0;
    double total = _healthStore.records.fold(0, (sum, r) => sum + r.bmi);
    return total / _healthStore.records.length;
  }

  double calculateAvgHR() {
    if (_healthStore.records.isEmpty) return 0.0;
    double total = _healthStore.records.fold(0, (sum, r) => sum + r.heartRate);
    return total / _healthStore.records.length;
  }

  Map<String, double> getCategoryDistribution() {
    Map<String, double> distribution = {};
    for (var activity in activities) {
      String cat = activity['category'] ?? 'Other';
      distribution[cat] = (distribution[cat] ?? 0) + 1;
    }
    return distribution;
  }

  /// Returns counts of products per each productCategory, dynamically.
  List<double> getProductTypeData() {
    return productCategories.map((cat) {
      int count = products.where((p) {
        return (p['category'] ?? '').toUpperCase() == cat.toUpperCase();
      }).length;
      return count.toDouble();
    }).toList();
  }

  // CRUD Actions
  void addActivity(Map<String, String> activity) {
    activities = [activity, ...activities];
    _saveToDisk();
  }

  void addCategory(String category) {
    if (!categories.contains(category)) {
      categories.add(category);
      _saveToDisk();
    }
  }

  void addProductCategory(String category) {
    if (!productCategories.contains(category)) {
      productCategories.add(category);
      _saveToDisk();
    }
  }

  void removeCategory(String category) {
    categories.remove(category);
    _saveToDisk();
  }

  void removeProductCategory(String category) {
    productCategories.remove(category);
    _saveToDisk();
  }

  void updateActivity(String id, Map<String, String> updatedActivity) {
    final index = activities.indexWhere((a) => a['id'] == id);
    if (index != -1) {
      activities = List.from(activities)..[index] = updatedActivity;
      _saveToDisk();
    }
  }

  void removeActivity(String id) {
    activities = List.from(activities)..removeWhere((a) => a['id'] == id);
    _saveToDisk();
  }

  void addProduct(Map<String, String> product) {
    products = [product, ...products];
    _saveToDisk();
  }

  void updateProduct(String id, Map<String, String> updatedProduct) {
    final index = products.indexWhere((p) => p['id'] == id);
    if (index != -1) {
      products = List.from(products)..[index] = updatedProduct;
      _saveToDisk();
    }
  }

  void removeProduct(String id) {
    products = List.from(products)..removeWhere((p) => p['id'] == id);
    _saveToDisk();
  }

  void addAnnouncement(Map<String, String> announcement) {
    announcements = [announcement, ...announcements];
    _hasNewAnnouncements = true;
    _saveToDisk();
  }

  void updateAnnouncement(String id, Map<String, String> updatedAnnouncement) {
    final index = announcements.indexWhere((a) => a['id'] == id);
    if (index != -1) {
      announcements = List.from(announcements)..[index] = updatedAnnouncement;
      _saveToDisk();
    }
  }

  void removeAnnouncement(String id) {
    announcements = List.from(announcements)..removeWhere((a) => a['id'] == id);
    _saveToDisk();
  }

  void trackLogout() {
    totalLogouts++;
    _saveToDisk();
  }
}
