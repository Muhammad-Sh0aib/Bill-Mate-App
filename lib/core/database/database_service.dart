import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import 'database_schema.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService _instance = DatabaseService._();

  static DatabaseService get instance => _instance;

  Database? _database;
  Future<Database>? _initialization;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_initialization != null) return _initialization!;

    final completer = Completer<Database>();
    _initialization = completer.future;

    try {
      final path = kIsWeb
          ? AppConstants.databaseName
          : p.join(await getDatabasesPath(), AppConstants.databaseName);
      final database = await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
      _database = database;
      completer.complete(database);
      return database;
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await DatabaseSchema.create(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await DatabaseSchema.upgrade(db);
    }
  }

  Future<void> close() async {
    final database = _database;
    if (database != null) {
      await database.close();
      _database = null;
      _initialization = null;
    }
  }
}
