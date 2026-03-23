import 'package:firebase_database/firebase_database.dart';
import '../models/classroom_model.dart';

/// Singleton service for Firebase Realtime Database.
/// Streams live classroom sensor data from the /classroom node.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final DatabaseReference _ref =
      FirebaseDatabase.instance.ref('classroom');

  /// Realtime stream — emits a new [ClassroomModel] on every ESP32 update.
  Stream<ClassroomModel> get classroomStream {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return ClassroomModel.empty();
      return ClassroomModel.fromMap(data as Map<dynamic, dynamic>);
    });
  }
}
