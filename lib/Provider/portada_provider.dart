import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PortadaProvider extends ChangeNotifier {
  Future<List> getPortada() async {
    List portada = [];
    CollectionReference portadaCollection = FirebaseFirestore.instance
        .collection("Portada");
    QuerySnapshot snapshot = await portadaCollection.get();
    for (var doc in snapshot.docs) {
      portada.add(doc.data());
    }
    return portada;
  }

  static PortadaProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<PortadaProvider>(context, listen: listen);
  }
}
