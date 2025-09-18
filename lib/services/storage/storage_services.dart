import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final StorageService I = StorageService._();
  StorageService._();

  final _storage = FirebaseStorage.instance;

  Future<String> uploadIdImage({
    required File file,
    required String uid,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('ids/$uid/$ts.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }
}
