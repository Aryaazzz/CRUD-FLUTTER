import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // Sesuaikan dengan lokasi class UserData

class FirebaseService {
  static const String collectionName = 'users';
  final CollectionReference _userRef =
      FirebaseFirestore.instance.collection(collectionName);

  // 1. CREATE: Tambah data dengan Auto-ID
  Future<void> tambah(UserData user) async {
    await _userRef.add(user.toJson());
  }

  // 2. READ: Ambil data secara Real-time (Stream)
  Stream<List<UserData>> ambilData() {
    return _userRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserData.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // 3. UPDATE: Perbarui data berdasarkan Document ID
  Future<void> update(String docId, UserData user) async {
    await _userRef.doc(docId).update(user.toJson());
  }

  // 4. DELETE: Hapus data berdasarkan Document ID
  Future<void> hapus(String docId) async {
    await _userRef.doc(docId).delete();
  }
}