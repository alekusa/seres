import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Modelo simplificado para el contenido exclusivo
class ExclusiveContent {
  final String id;
  final String title;
  final String description;
  final String type; // 'audio', 'video', 'meditation'
  final String contentUrl; // URL de YouTube o MP3
  final String duration;

  ExclusiveContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.contentUrl,
    required this.duration,
  });

  factory ExclusiveContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExclusiveContent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'video',
      contentUrl: data['contentUrl'] ?? '',
      duration: data['duration'] ?? '',
    );
  }
}

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isVip = false;

  bool get isVip => _isVip;
  User? get currentUser => _currentUser;

  UserProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _currentUser = user;
      _isVip = false; // Reset al cambiar de usuario

      if (user != null) {
        _listenToUserRole(user.uid);
      } else {
        notifyListeners();
      }
    });
  }

  void _listenToUserRole(String uid) {
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((
      DocumentSnapshot snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        // Verifica si tiene el rol 'vip' o 'isPremium' true
        _isVip = data?['role'] == 'vip' || data?['isPremium'] == true;
      } else {
        _isVip = false;
      }
      notifyListeners();
    });
  }

  // Stream de contenidos exclusivos
  Stream<List<ExclusiveContent>> get exclusiveContentStream {
    if (!_isVip) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('exclusive_content')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ExclusiveContent.fromFirestore(doc))
                  .toList(),
        );
  }

  // Logout
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static UserProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<UserProvider>(context, listen: listen);
  }
}
