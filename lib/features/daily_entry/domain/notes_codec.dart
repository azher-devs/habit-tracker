import 'dart:convert';

/// Encodes and validates the text-only Quill Delta format used for notes.
abstract final class NotesCodec {
  static const emptyDelta = <Map<String, Object?>>[
    {'insert': '\n'},
  ];

  static List<Map<String, dynamic>> decode(String? json) {
    if (json == null || json.trim().isEmpty) {
      return [for (final op in emptyDelta) Map<String, dynamic>.from(op)];
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      // Older releases stored notes as plain text before Delta JSON was added.
      return _legacyText(json);
    }
    if (decoded is String) return _legacyText(decoded);
    if (decoded is! List || decoded.isEmpty) {
      throw const FormatException('A Quill Delta must be a non-empty list');
    }
    final operations = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is! Map || item['insert'] is! String) {
        throw const FormatException(
          'Only text insert operations are supported',
        );
      }
      final attributes = item['attributes'];
      if (attributes != null && attributes is! Map) {
        throw const FormatException('Delta attributes must be an object');
      }
      if (item.keys.any((key) => key != 'insert' && key != 'attributes')) {
        throw const FormatException('Only insert operations are supported');
      }
      if (attributes is Map) {
        for (final entry in attributes.entries) {
          final valid = switch (entry.key) {
            'bold' || 'italic' || 'underline' => entry.value is bool,
            'header' =>
              entry.value is int && entry.value >= 1 && entry.value <= 6,
            'list' => entry.value == 'bullet' || entry.value == 'ordered',
            _ => false,
          };
          if (!valid) {
            throw const FormatException('Unsupported Delta formatting');
          }
        }
      }
      operations.add(Map<String, dynamic>.from(item));
    }
    return operations;
  }

  static List<Map<String, dynamic>> _legacyText(String text) {
    final insert = text.endsWith('\n') ? text : '$text\n';
    return [
      <String, dynamic>{'insert': insert},
    ];
  }

  /// Empty editor content is stored as no note, leaving the entry lazy.
  static String? encode(List<Map<String, dynamic>> operations) {
    final valid = decode(jsonEncode(operations));
    final text = valid.map((op) => op['insert'] as String).join();
    if (text.replaceAll('\n', '').trim().isEmpty) return null;
    return jsonEncode(valid);
  }
}
