import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gym_app.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // Seed default admin and user
    await db.insert('users', {
      'id': 'admin-uuid-1234',
      'name': 'Pulse Admin',
      'email': 'admin@purepulse.com',
      'password': 'admin123',
      'role': 'admin',
    });

    // 2. Workouts table
    await db.execute('''
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        duration TEXT NOT NULL,
        exercise TEXT NOT NULL,
        intensity TEXT NOT NULL,
        weight TEXT NOT NULL,
        sets TEXT NOT NULL,
        reps TEXT NOT NULL,
        calories TEXT,
        achievement TEXT,
        notes TEXT
      )
    ''');

    // 3. Health records table
    await db.execute('''
      CREATE TABLE health_records (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        systolic REAL NOT NULL,
        diastolic REAL NOT NULL,
        heartRate REAL NOT NULL,
        bloodSugar REAL NOT NULL,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        bmi REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // 4. Activities table
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        image TEXT NOT NULL,
        category TEXT NOT NULL,
        duration TEXT NOT NULL,
        warmup TEXT NOT NULL,
        mainWorkout TEXT NOT NULL,
        rest TEXT NOT NULL
      )
    ''');

    // Seed default activities
    final defaultActivities = [
      {
        'id': '1',
        'title': 'Full Cardio Burn',
        'description': 'Complete cardio session for endurance and fat burn',
        'image': 'assets/full_cardioburn_image.jpg',
        'category': 'Cardio',
        'duration': '45 mins',
        'warmup': '5 mins jog',
        'mainWorkout': 'HIIT intervals on treadmill',
        'rest': '5 mins stretch',
      },
      {
        'id': '2',
        'title': 'Strength Power Set',
        'description': 'Full body strength training with compound movements',
        'image': 'assets/strength_power_set_image.png',
        'category': 'Strength',
        'duration': '60 mins',
        'warmup': 'Dynamic stretching',
        'mainWorkout': 'Squats, Bench Press, Deadlifts',
        'rest': '3 mins between sets',
      },
      {
        'id': '3',
        'title': 'Running',
        'description': 'Outdoor or treadmill running',
        'image': 'assets/running_image.jpg',
        'category': 'Cardio',
        'duration': '30 mins',
        'warmup': 'Stretching',
        'mainWorkout': '5k steady pace run',
        'rest': 'Cool down walk',
      },
      {
        'id': '4',
        'title': 'Dynamic Aerobics',
        'description':
            'High-energy aerobic workout for flexibility and stamina',
        'image': 'assets/dynamic_aerobics_image.jpg',
        'category': 'Aerobics',
        'duration': '40 mins',
        'warmup': 'Aerobic warm up',
        'mainWorkout': 'High intensity choreo aerobics',
        'rest': 'Light stretching',
      },
      {
        'id': '5',
        'title': 'Jump Rope',
        'description': 'High intensity jump rope',
        'image': 'assets/jumping_image.jpg',
        'category': 'Cardio',
        'duration': '20 mins',
        'warmup': 'Wrist & ankle mobility',
        'mainWorkout': 'Jump rope intervals',
        'rest': 'Deep breathing',
      },
      {
        'id': '6',
        'title': 'Cycling',
        'description': 'Stationary or outdoor cycling',
        'image': 'assets/cycling_image.png',
        'category': 'Cardio',
        'duration': '45 mins',
        'warmup': 'Slow spin 5 mins',
        'mainWorkout': 'Hill climb intervals',
        'rest': 'Cool down spin 5 mins',
      },
    ];

    for (var act in defaultActivities) {
      await db.insert('activities', act);
    }

    // 5. Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        image TEXT NOT NULL
      )
    ''');

    // Seed default products
    final defaultProducts = [
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
        'description':
            'Free-weight dumbbells designed for heavy commercial use.',
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
        'title': 'Whey Isolate Protein',
        'description':
            'High Quality Hydrolyzed & Ultra-Filtered Whey Protein Isolate',
        'category': 'SUPPLEMENTS',
        'image': 'assets/protein.png',
      },
    ];

    for (var prod in defaultProducts) {
      await db.insert('products', prod);
    }

    // 6. Announcements table
    await db.execute('''
      CREATE TABLE announcements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Seed default announcements
    final defaultAnnouncements = [
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

    for (var ann in defaultAnnouncements) {
      await db.insert('announcements', ann);
    }
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users');
    await db.delete('workouts');
    await db.delete('health_records');
    await db.delete('activities');
    await db.delete('products');
    await db.delete('announcements');
  }
}
