import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<AppUser?> getUserByUid(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
