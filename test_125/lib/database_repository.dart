import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QueueModel {
  final int? id;
  final String customerName;
  final int pax;
  final String zone;
  final String createdAt;

  QueueModel({
    this.id,
    required this.customerName,
    required this.pax,
    required this.zone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'pax': pax,
      'zone': zone,
      'createdAt': createdAt,
    };
  }

  factory QueueModel.fromMap(Map<String, dynamic> map) {
    return QueueModel(
      id: map['id'],
      customerName: map['customerName'],
      pax: map['pax'],
      zone: map['zone'],
      createdAt: map['createdAt'],
    );
  }
}

class DatabaseRepository {
  static final DatabaseRepository instance = DatabaseRepository._init();
  static Database? _database;

  DatabaseRepository._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('restaurant_queue.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE queues (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerName TEXT NOT NULL,
            pax INTEGER NOT NULL,
            zone TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insert(QueueModel queue) async {
    final db = await instance.database;
    return await db.insert('queues', queue.toMap());
  }

  Future<List<QueueModel>> get() async {
    final db = await instance.database;
    final result = await db.query('queues', orderBy: 'id DESC');
    return result.map((json) => QueueModel.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('queues', where: 'id = ?', whereArgs: [id]);
  }
}