import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const dbName = 'purchase_sessions.db';
  static const dbVersion = 1;

  Database? _db;
  String? _dbPath;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, dbName);
    _dbPath = path;

    _db = await openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
    );

    return _db!;
  }

  Future<String> get databasePath async {
    if (_dbPath != null) return _dbPath!;

    final dir = await getApplicationDocumentsDirectory();
    _dbPath = p.join(dir.path, dbName);
    return _dbPath!;
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
    _db = null;
    _dbPath = null;
  }

  Future<void> resetConnection() async {
    await close();
    await database;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('open', 'closed'))
      );
    ''');

    await db.execute('''
      CREATE TABLE invoices(
        id TEXT PRIMARY KEY,
        sessionId TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        reference TEXT NOT NULL,
        supplier TEXT NULL,
        amountInitialRmb REAL NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE corrections(
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
        date TEXT NOT NULL,
        amountRmb REAL NOT NULL,
        reason TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE payments(
        id TEXT PRIMARY KEY,
        sessionId TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        date TEXT NOT NULL,
        amountMga REAL NOT NULL,
        exchangeRate REAL NOT NULL,
        amountRmbComputed REAL NOT NULL,
        note TEXT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE attachments(
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL CHECK (type IN ('invoice', 'payment')),
        elementId TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileSize INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE audit_logs(
        id TEXT PRIMARY KEY,
        tableName TEXT NOT NULL,
        elementId TEXT NOT NULL,
        oldValueJson TEXT NULL,
        newValueJson TEXT NULL,
        actionType TEXT NOT NULL,
        createdAt TEXT NOT NULL
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_invoices_sessionId ON invoices(sessionId);',
    );
    await db.execute(
      'CREATE INDEX idx_payments_sessionId ON payments(sessionId);',
    );
    await db.execute(
      'CREATE INDEX idx_corrections_invoiceId ON corrections(invoiceId);',
    );
    await db.execute(
      'CREATE INDEX idx_attach_element ON attachments(elementId, type);',
    );
    await db.execute(
      'CREATE INDEX idx_audit_element ON audit_logs(tableName, elementId);',
    );
  }
}
