import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingService {
  static final _db = FirebaseFirestore.instance;

  /// Writes one shopping item document to the shared couple list.
  /// Returns null on success, or an error message string on failure.
  static Future<String?> addItem({
    required String name,
    required String createdByRef,
    required String coupleRef,
  }) async {
    try {
      await _db.collection('shopping_items').add({
        'name': name,
        'createdByRef': createdByRef,
        'coupleRef': coupleRef,
        'createdAt': FieldValue.serverTimestamp(),
        'isCompleted': false,
        'completedByRef': null,
        'completedAt': null,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
