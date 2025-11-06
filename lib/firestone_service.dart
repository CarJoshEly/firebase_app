import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoneService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //Crear Nota

  Future<void> addNote(String text, String category) async {
    await _db.collection('notes').add({
      'text': text,
      'category': category,
      'createdAt': DateTime.now(),
    });
  }

  //Leer Notas

  Stream<QuerySnapshot> getNotesStream() {
    return _db.collection('notes').orderBy('createdAt', descending: true).snapshots();
  }


  //Update Nota

  Future<void> updateNote(String id, String text, String category) async {
    await _db.collection('notes').doc(id).update({'text':text, 'category': category});
  }

//Delete Nota

  Future<void> deleteNote(String id,) async{
    await _db.collection('notes').doc(id).delete();
  }
}