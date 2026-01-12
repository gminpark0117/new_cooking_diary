import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';

class DiaryEntry {
  static const Uuid _uuid = Uuid();

  DiaryEntry({
    String? id,
    this.imagePath,
    required this.recipeName,
    this.note,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String? imagePath;
  final String recipeName;
  final String? note;
}

class DiaryEntryRepository {
  DiaryEntryRepository(this._db);

  final AppDb _db;

  // Folder under app documents directory where we store managed diary images
  static const String _imagesDirName = 'diary_images';

  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    final db = await _db.db;

    final rows = await db.query('diary_entries');
    return rows.map((r) {
      return DiaryEntry(
        id: r['id'] as String,
        imagePath: r['image_path'] as String?,
        recipeName: r['recipe_name'] as String,
        note: r['note'] as String?,
      );
    }).toList();
  }

  /// Upserts the diary entry row.
  ///
  /// File behavior:
  /// - If entry.imagePath is null/empty: stores NULL in DB; deletes old managed image (if any).
  /// - If entry.imagePath points outside app-managed directory: copies it into app storage and stores the new path.
  /// - If entry.imagePath already points to app-managed directory: uses it as-is.
  /// - If the image changes, the old managed image is deleted (best-effort).
  Future<DiaryEntry> upsertDiaryEntry(DiaryEntry entry) async {
    final db = await _db.db;

    // Read the existing image path (if any) so we can delete it if replaced/removed
    final oldPath = await _getExistingImagePath(db, entry.id);

    // Decide what path we will store in DB, possibly copying into app storage
    String? newStoredPath = _normalizeNullablePath(entry.imagePath);
    String? newlyCopiedPath; // track for cleanup if DB fails

    if (newStoredPath != null) {
      final imageChanged = oldPath == null || newStoredPath != oldPath; // if newStoredPath == oldPath, oldPath definitely must be under imagesDir. no need to ensure

      if (imageChanged) {
        final appImagesDir = await _ensureImagesDir();

        newlyCopiedPath = await _copyIntoAppDir(
          sourcePath: newStoredPath,
          entryId: entry.id,
          imagesDir: appImagesDir,
        );

        newStoredPath = newlyCopiedPath;
      }
    }

    try {
      await db.transaction((txn) async {
        await txn.insert(
          'diary_entries',
          {
            'id': entry.id,
            'image_path': newStoredPath,
            'recipe_name': entry.recipeName,
            'note': entry.note,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (_) {
      // If DB write failed after we copied a file, remove the newly-copied file to avoid orphan files.
      if (newlyCopiedPath != null) {
        await _deleteFileBestEffort(newlyCopiedPath);
      }
      rethrow;
    }

    // DB write succeeded. If the image changed/removed, delete the old managed image.
    if (oldPath != null && oldPath != newStoredPath) {
      final appImagesDir = await _ensureImagesDir();
      if (_isUnderDir(oldPath, appImagesDir)) {
        await _deleteFileBestEffort(oldPath);
      }
    }

    // Return canonical entry (same id, but imagePath updated)
    return DiaryEntry(
      id: entry.id,
      imagePath: newStoredPath,
      recipeName: entry.recipeName,
      note: entry.note,
    );
  }

  /// Deletes the diary entry row and its managed image file (best-effort).
  Future<void> deleteDiaryEntry(DiaryEntry entry) async {
    final db = await _db.db;

    final existingPath = await _getExistingImagePath(db, entry.id);

    await db.delete('diary_entries', where: 'id = ?', whereArgs: [entry.id]);

    if (existingPath != null) {
      final appImagesDir = await _ensureImagesDir();
      if (_isUnderDir(existingPath, appImagesDir)) {
        await _deleteFileBestEffort(existingPath);
      }
    }
  }

  // ---------- Helpers ----------

  Future<String?> _getExistingImagePath(Database db, String id) async {
    final rows = await db.query(
      'diary_entries',
      columns: ['image_path'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final path = rows.first['image_path'] as String?;
    return _normalizeNullablePath(path);
  }

  String? _normalizeNullablePath(String? path) {
    final s = path?.trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  Future<String> _ensureImagesDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = p.join(dir.path, _imagesDirName);

    final d = Directory(imagesDir);
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return imagesDir;
  }

  bool _isUnderDir(String filePath, String dirPath) {
    final normalizedFile = p.normalize(filePath);
    final normalizedDir = p.normalize(dirPath);

    // Ensure trailing separator so "/a/b1" doesn't match "/a/b"
    final dirWithSep = normalizedDir.endsWith(p.separator)
        ? normalizedDir
        : '$normalizedDir${p.separator}';

    return normalizedFile.startsWith(dirWithSep);
  }

  Future<String> _copyIntoAppDir({
    required String sourcePath,
    required String entryId,
    required String imagesDir,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw StateError('Selected image file does not exist: $sourcePath');
    }

    final ext = p.extension(sourcePath); // includes ".jpg", ".png", etc.
    final filename = 'diary_${entryId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(imagesDir, filename);

    await sourceFile.copy(destPath);
    return destPath;
  }

  Future<void> _deleteFileBestEffort(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {
      // Best-effort: ignore file delete errors (permission, already deleted, etc.)
    }
  }
}