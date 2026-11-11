import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ContactDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'contacts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT,
            isFavorite INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> addContact({
    required String name,
    required String phone,
    String email = '',
  }) async {
    final db = await database;

    return await db.insert('contacts', {
      'name': name,
      'phone': phone,
      'email': email,
      'isFavorite': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await database;

    return await db.query('contacts', orderBy: 'name COLLATE NOCASE ASC');
  }

  Future<int> updateContact({
    required int id,
    required String name,
    required String phone,
    String email = '',
    required bool isFavorite,
  }) async {
    final db = await database;

    return await db.update(
      'contacts',
      {
        'name': name,
        'phone': phone,
        'email': email,
        'isFavorite': isFavorite ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await database;

    return await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }
}
