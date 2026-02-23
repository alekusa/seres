import 'package:SERES/Provider/portada_provider.dart';
import 'package:SERES/Utils/constant.dart';
import 'package:SERES/Widget/banner.dart';
import 'package:SERES/Widget/food_items_display.dart';
import 'package:SERES/Widget/my_icon_button.dart';
import 'package:SERES/services/notification_service.dart';
import 'package:SERES/views/view_all_items.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAppHomeScreen extends StatefulWidget {
  final VoidCallback? onTalleresPressed;
  const MyAppHomeScreen({super.key, this.onTalleresPressed});

  @override
  State<MyAppHomeScreen> createState() => _MyAppHomeScreenState();
}

class _MyAppHomeScreenState extends State<MyAppHomeScreen> {
  String category = "Todas";
  late Future<List> _portadaFuture;
  //for category
  final CollectionReference categoriesItems = FirebaseFirestore.instance
      .collection("App-Category");
  //for items
  Query get filteredRecipes => FirebaseFirestore.instance
      .collection("Complete-Flutter-App")
      .where("category", isEqualTo: category);
  Query get allRecipes =>
      FirebaseFirestore.instance.collection("Complete-Flutter-App");
  Query get selectedRecipes =>
      category == "Todas" ? allRecipes : filteredRecipes;

  @override
  void initState() {
    super.initState();
    _portadaFuture = PortadaProvider().getPortada();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kbackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerParts(),
                          //Barra de Busqueda proximamente !
                          //mySearchBar(),
                          BannerToExplore(onTap: widget.onTalleresPressed),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: FutureBuilder(
                              future: _portadaFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text("Error: ${snapshot.error}");
                                } else {
                                  List portada = snapshot.data as List;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        portada.map((item) {
                                          return Text(
                                            item['titulo_1'] ?? '',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList(),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    selectedCategory(),
                    SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Contenidos",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ViewAllItems(),
                              ),
                            );
                          },
                          child: const Text(
                            "Ver todo",
                            style: TextStyle(
                              color: Color.fromARGB(255, 116, 142, 222),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StreamBuilder(
                stream: selectedRecipes.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    final List<DocumentSnapshot> recipes =
                        snapshot.data?.docs ?? [];
                    return Padding(
                      padding: EdgeInsets.only(top: 5, left: 15),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              recipes
                                  .map(
                                    (e) =>
                                        FoodItemsDisplay(documentSnapshot: e),
                                  )
                                  .toList(),
                        ),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  StreamBuilder<QuerySnapshot<Object?>> selectedCategory() {
    return StreamBuilder(
      stream: categoriesItems.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
        if (streamSnapshot.hasData) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                streamSnapshot.data!.docs.length,
                (index) => GestureDetector(
                  onTap: () {
                    setState(() {
                      category = streamSnapshot.data!.docs[index]["name"];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color:
                          category == streamSnapshot.data!.docs[index]["name"]
                              ? kprimaryColor
                              : Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    margin: EdgeInsets.only(right: 20),
                    child: Text(
                      streamSnapshot.data!.docs[index]["name"],
                      style: TextStyle(
                        color:
                            category == streamSnapshot.data!.docs[index]["name"]
                                ? Colors.white
                                : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Padding mySearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          prefixIcon: const Icon(Iconsax.search_normal),
          fillColor: Colors.white,
          border: InputBorder.none,
          hintText: "Buscar",
          hintStyle: const TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Row headerParts() {
    return Row(
      children: [
        Text(
          "SERES",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        const Spacer(),
        MyIconButton(
          icon: Iconsax.notification,
          pressed: () async {
            await NotificationService().requestPermission();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notificaciones activadas'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
