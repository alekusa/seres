import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoriteProvider extends ChangeNotifier {
  List<String> _favoriteIds = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> get favorites => _favoriteIds;

  FavoriteProvider() {
    _auth.authStateChanges().listen((user) {
      loadFavorites();
    });
  }

  // Get user-specific favorites collection reference
  CollectionReference? get _favoritesCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  void toggleFavorite(DocumentSnapshot product) async {
    String productId = product.id;
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      await _removeFavorite(productId);
    } else {
      _favoriteIds.add(productId);
      await _addFavorite(productId);
    }
    notifyListeners();
  }

  bool isExists(DocumentSnapshot product) {
    return _favoriteIds.contains(product.id);
  }

  Future<void> _addFavorite(String productId) async {
    try {
      final collection = _favoritesCollection;
      if (collection == null) {
        print('User not authenticated');
        return;
      }

      await collection.doc(productId).set({
        'isFavorite': true,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      final collection = _favoritesCollection;
      if (collection == null) {
        print('User not authenticated');
        return;
      }

      await collection.doc(productId).delete();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> loadFavorites() async {
    try {
      final collection = _favoritesCollection;
      if (collection == null) {
        _favoriteIds = [];
        notifyListeners();
        return;
      }

      QuerySnapshot snapshot = await collection.get();
      _favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print(e.toString());
    }
    notifyListeners();
  }

  static FavoriteProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<FavoriteProvider>(context, listen: listen);
  }
}
