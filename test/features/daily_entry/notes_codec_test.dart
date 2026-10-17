import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/daily_entry/domain/notes_codec.dart';

void main() {
  test('round trips supported Quill text Delta operations', () {
    const delta =
        '[{"insert":"Heading\\n","attributes":{"header":1}},'
        '{"insert":"bold","attributes":{"bold":true}},'
        '{"insert":"italic","attributes":{"italic":true}},'
        '{"insert":"underline","attributes":{"underline":true}},'
        '{"insert":"\\nitem\\n","attributes":{"list":"bullet"}},'
        '{"insert":"\\nstep\\n","attributes":{"list":"ordered"}},'
        '{"insert":"Section\\n","attributes":{"header":6}}]';
    expect(NotesCodec.decode(delta), hasLength(7));
    expect(NotesCodec.encode(NotesCodec.decode(delta)), delta);
  });

  test('empty and malformed content are handled explicitly', () {
    expect(NotesCodec.decode(null), NotesCodec.emptyDelta);
    expect(NotesCodec.encode(NotesCodec.emptyDelta), isNull);
    expect(() => NotesCodec.decode('{}'), throwsFormatException);
    expect(() => NotesCodec.decode('[{"insert": {}}]'), throwsFormatException);
    expect(
      () => NotesCodec.decode(
        '[{"insert":"text","attributes":{"link":"https://example.com"}}]',
      ),
      throwsFormatException,
    );
  });

  test('keeps legacy plain-text notes readable as a Delta', () {
    expect(NotesCodec.decode('ملاحظة عربية\nMixed English'), [
      <String, dynamic>{'insert': 'ملاحظة عربية\nMixed English\n'},
    ]);
    expect(
      NotesCodec.encode(NotesCodec.decode('ملاحظة قديمة')),
      '[{"insert":"ملاحظة قديمة\\n"}]',
    );
  });
}
