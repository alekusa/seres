import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  Map<String, dynamic>? _userData;
  bool _isVip = false;

  bool get isVip => _isVip;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;

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
        _userData = snapshot.data() as Map<String, dynamic>?;
        // Verifica si tiene el rol 'vip' true
        _isVip = _userData?['role'] == 'vip' || _userData?['isPremium'] == true;
      } else {
        _userData = null;
        _isVip = false;
      }
      notifyListeners();
    });
  }

  // Actualizar perfil del usuario
  Future<void> updateProfile({
    String? displayName,
    String? birthDate,
    String? address,
    String? phone,
    String? photoURL,
  }) async {
    if (_currentUser == null) return;

    final Map<String, dynamic> updates = {};
    if (_currentUser?.email != null) updates['email'] = _currentUser!.email;
    if (displayName != null) updates['displayName'] = displayName;
    if (birthDate != null) updates['birthDate'] = birthDate;
    if (address != null) updates['address'] = address;
    if (phone != null) updates['phone'] = phone;
    if (photoURL != null) updates['photoURL'] = photoURL;

    if (updates.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .set(updates, SetOptions(merge: true));

    if (displayName != null || photoURL != null) {
      await _currentUser!.updateDisplayName(
        displayName ?? _currentUser!.displayName,
      );
      await _currentUser!.updatePhotoURL(photoURL ?? _currentUser!.photoURL);
      await _currentUser!.reload();
      _currentUser = FirebaseAuth.instance.currentUser;
    }
    notifyListeners();
  }

  // Subir imagen a Cloudinary (Método manual para Debugging)
  Future<String?> uploadProfileImage(File imageFile) async {
    if (_currentUser == null) return null;

    final String cloudName = "devverudd";
    final String uploadPreset = "profiles";

    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request =
          http.MultipartRequest("POST", uri)
            ..fields['upload_preset'] = uploadPreset
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path),
            );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(responseString);
        final url = jsonResponse['secure_url'];

        await updateProfile(photoURL: url);
        return url;
      } else {
        debugPrint("--- CLOUDINARY UPLOAD ERROR ---");
        debugPrint("Status Code: ${response.statusCode}");
        debugPrint("Response Body: $responseString");
        return null;
      }
    } catch (e) {
      debugPrint("--- CLOUDINARY EXCEPTION ---");
      debugPrint("Error: $e");
      return null;
    }
  }

  // Sincronizar con foto de Google
  Future<void> syncWithGooglePhoto() async {
    if (_currentUser == null) return;

    // Si el usuario se logueó con Google, Firebase Auth ya tiene su foto en photoURL inicialmente
    // Pero si la cambió, podemos intentar obtenerla de nuevo si es necesario.
    // En este caso, simplemente asumimos que si el proveedor es Google, podemos "resetear" a la foto del proveedor.
    for (UserInfo userInfo in _currentUser!.providerData) {
      if (userInfo.providerId == 'google.com' && userInfo.photoURL != null) {
        await updateProfile(photoURL: userInfo.photoURL);
        break;
      }
    }
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
