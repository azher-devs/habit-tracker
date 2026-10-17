import 'dart:convert';

import 'package:archive/archive.dart';

import '../../core/database/app_database.dart';
import '../../features/daily_entry/domain/entry_status.dart';
import '../../features/daily_entry/domain/notes_codec.dart';
import '../utils/date_key.dart';
import 'backup_exception.dart';
import 'backup_models.dart';

abstract final class BackupValidator {
  static const maxArchiveBytes = 50 * 1024 * 1024;
  static const maxFileBytes = 20 * 1024 * 1024;
  static const _requiredFiles = {
    'manifest.json',
    'folders.json',
    'daily_entries.json',
    'settings.json',
  };
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final _isoTimestamp = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$',
  );

  static BackupDocument decode(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > maxArchiveBytes) {
      throw const BackupFormatException('حجم ملف النسخة غير صالح.');
    }
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      if (archive.files.length != _requiredFiles.length) {
        throw const BackupFormatException('محتويات ملف النسخة غير مكتملة.');
      }
      final data = <String, Object?>{};
      for (final file in archive.files) {
        final name = file.name;
        if (name.isEmpty ||
            name.contains('/') ||
            name.contains('\\') ||
            name.contains('..') ||
            name.startsWith('/') ||
            name.contains(':') ||
            file.isDirectory ||
            file.isSymbolicLink ||
            !_requiredFiles.contains(name)) {
          throw const BackupFormatException('يحتوي الملف على مسار غير مسموح.');
        }
        if (file.size < 0 || file.size > maxFileBytes) {
          throw const BackupFormatException(
            'أحد ملفات النسخة أكبر من المسموح.',
          );
        }
        final content = file.readBytes();
        if (content == null || content.length != file.size) {
          throw const BackupFormatException('تعذر قراءة أحد ملفات النسخة.');
        }
        if (data.containsKey(name)) {
          throw const BackupFormatException('توجد ملفات مكررة في النسخة.');
        }
        data[name] = jsonDecode(utf8.decode(content));
      }
      if (data.keys.toSet().difference(_requiredFiles).isNotEmpty ||
          !_requiredFiles.every(data.containsKey)) {
        throw const BackupFormatException('ملفات النسخة المطلوبة غير موجودة.');
      }
      return _parse(data);
    } on BackupFormatException {
      rethrow;
    } catch (error) {
      throw BackupFormatException('تعذر قراءة ملف النسخة: $error');
    }
  }

  static BackupDocument _parse(Map<String, Object?> data) {
    final manifest = _object(data['manifest.json'], 'manifest');
    _requireFields(manifest, {
      'format',
      'formatVersion',
      'schemaVersion',
      'exportedAt',
      'appVersion',
      'counts',
    });
    if (manifest['format'] != 'daytracker-backup') {
      throw const BackupFormatException('صيغة ملف النسخة غير معروفة.');
    }
    final formatVersion = _integer(manifest['formatVersion'], 'formatVersion');
    final schemaVersion = _integer(manifest['schemaVersion'], 'schemaVersion');
    if (formatVersion < 1 || formatVersion > 1) {
      throw const BackupFormatException('إصدار ملف النسخة غير مدعوم.');
    }
    if (schemaVersion < 1 || schemaVersion > AppDatabase.currentSchemaVersion) {
      throw const BackupFormatException('إصدار قاعدة البيانات غير مدعوم.');
    }
    final exportedAt = _dateTime(manifest['exportedAt'], 'exportedAt');
    final appVersion = manifest['appVersion'];
    if (appVersion is! String || appVersion.trim().isEmpty) {
      throw const BackupFormatException('إصدار التطبيق في النسخة غير صالح.');
    }

    final rawFolders = _list(data['folders.json'], 'folders');
    final rawEntries = _list(data['daily_entries.json'], 'daily_entries');
    if (rawFolders.length > 10000 || rawEntries.length > 1000000) {
      throw const BackupFormatException('عدد السجلات في النسخة يتجاوز الحد.');
    }
    final folders = <BackupFolder>[];
    final folderIds = <String>{};
    for (final item in rawFolders) {
      final value = _object(item, 'folder');
      _requireFields(value, {
        'id',
        'name',
        'color',
        'iconCode',
        'sortOrder',
        'isArchived',
        'createdAt',
        'updatedAt',
      });
      final id = _id(value['id'], 'folder id');
      final name = value['name'];
      if (name is! String || name.trim().isEmpty || name.trim().length > 60) {
        throw const BackupFormatException('اسم مجلد في النسخة غير صالح.');
      }
      final color = _integer(value['color'], 'folder color');
      if (color < 0 || color > 0xffffffff) {
        throw const BackupFormatException('لون مجلد في النسخة غير صالح.');
      }
      final iconCode = value['iconCode'];
      if (iconCode != null && iconCode is! String) {
        throw const BackupFormatException('رمز مجلد في النسخة غير صالح.');
      }
      final sortOrder = _integer(value['sortOrder'], 'sortOrder');
      final isArchived = value['isArchived'];
      if (sortOrder < 0 || isArchived is! bool || !folderIds.add(id)) {
        throw const BackupFormatException('بيانات مجلد مكررة أو غير صالحة.');
      }
      folders.add(
        BackupFolder(
          id: id,
          name: name.trim(),
          color: color,
          iconCode: iconCode as String?,
          sortOrder: sortOrder,
          isArchived: isArchived,
          createdAt: _dateTime(value['createdAt'], 'createdAt'),
          updatedAt: _dateTime(value['updatedAt'], 'updatedAt'),
        ),
      );
    }

    final entries = <BackupEntry>[];
    final entryIds = <String>{};
    final folderDates = <String>{};
    for (final item in rawEntries) {
      final value = _object(item, 'entry');
      _requireFields(value, {
        'id',
        'folderId',
        'entryDate',
        'status',
        'notes',
        'createdAt',
        'updatedAt',
      });
      final id = _id(value['id'], 'entry id');
      final folderId = _id(value['folderId'], 'folderId');
      final date = value['entryDate'];
      if (date is! String || !DateKey.isValid(date)) {
        throw const BackupFormatException('تاريخ في النسخة غير صالح.');
      }
      final status = switch (value['status']) {
        null => null,
        'completed' => EntryStatus.completed,
        'missed' => EntryStatus.missed,
        _ => throw const BackupFormatException('حالة يوم غير معروفة.'),
      };
      final notes = value['notes'];
      String? notesJson;
      if (notes != null) {
        if (notes is! List) {
          throw const BackupFormatException('ملاحظات يوم غير صالحة.');
        }
        notesJson = jsonEncode(notes);
        if (NotesCodec.encode(NotesCodec.decode(notesJson)) == null) {
          throw const BackupFormatException('ملاحظة فارغة في ملف النسخة.');
        }
      }
      if (status == null && notesJson == null) {
        throw const BackupFormatException('سجل يوم فارغ في ملف النسخة.');
      }
      if (!folderIds.contains(folderId) ||
          !entryIds.add(id) ||
          !folderDates.add('$folderId|$date')) {
        throw const BackupFormatException('مرجع أو سجل يوم مكرر أو غير صالح.');
      }
      entries.add(
        BackupEntry(
          id: id,
          folderId: folderId,
          date: date,
          status: status,
          notesJson: notesJson,
          createdAt: _dateTime(value['createdAt'], 'createdAt'),
          updatedAt: _dateTime(value['updatedAt'], 'updatedAt'),
        ),
      );
    }

    final settingsObject = _object(data['settings.json'], 'settings');
    final settings = <String, String>{};
    for (final entry in settingsObject.entries) {
      if (entry.key.isEmpty || entry.value is! String) {
        throw const BackupFormatException('إعداد في ملف النسخة غير صالح.');
      }
      settings[entry.key] = entry.value as String;
    }
    final theme = settings['themeMode'];
    if (theme != null && !{'system', 'light', 'dark'}.contains(theme)) {
      throw const BackupFormatException('وضع المظهر في النسخة غير معروف.');
    }
    final language = settings['language'];
    if (language != null && !{'ar', 'en'}.contains(language)) {
      throw const BackupFormatException('لغة التطبيق في النسخة غير معروفة.');
    }
    final counts = _object(manifest['counts'], 'counts');
    if (_integer(counts['folders'], 'folder count') != folders.length ||
        _integer(counts['entries'], 'entry count') != entries.length) {
      throw const BackupFormatException('أعداد السجلات لا تطابق محتوى النسخة.');
    }
    return BackupDocument(
      formatVersion: formatVersion,
      schemaVersion: schemaVersion,
      exportedAt: exportedAt,
      appVersion: appVersion,
      folders: folders,
      entries: entries,
      settings: settings,
    );
  }

  static Map<String, Object?> _object(Object? value, String field) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw BackupFormatException('الحقل $field يجب أن يكون كائنًا.');
    }
    return Map<String, Object?>.from(value);
  }

  static void _requireFields(Map<String, Object?> object, Set<String> fields) {
    if (!fields.every(object.containsKey)) {
      throw const BackupFormatException('حقول مطلوبة مفقودة في ملف النسخة.');
    }
  }

  static List<Object?> _list(Object? value, String field) {
    if (value is! List) {
      throw BackupFormatException('الحقل $field يجب أن يكون قائمة.');
    }
    return value.cast<Object?>();
  }

  static int _integer(Object? value, String field) {
    if (value is! int) throw BackupFormatException('الحقل $field غير صالح.');
    return value;
  }

  static String _id(Object? value, String field) {
    if (value is! String || !_uuid.hasMatch(value)) {
      throw BackupFormatException('المعرّف $field غير صالح.');
    }
    return value;
  }

  static DateTime _dateTime(Object? value, String field) {
    if (value is! String || !_isoTimestamp.hasMatch(value)) {
      throw BackupFormatException('التاريخ $field غير صالح.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw BackupFormatException('التاريخ $field غير صالح.');
    return parsed.toUtc();
  }
}
