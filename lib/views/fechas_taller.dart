import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:SERES/Utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class FehcasTaller extends StatefulWidget {
  const FehcasTaller({super.key});

  @override
  State<FehcasTaller> createState() => _FehcasTallerState();
}

final DateTime now = DateTime.now();

class _FehcasTallerState extends State<FehcasTaller> {
  final String mes = DateFormat('MMMM').format(now);
  final String dia = DateFormat('dd').format(now);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset('assets/images/Equipo.jpeg'),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  alignment: Alignment.bottomRight,
                  child: RichText(
                    text: TextSpan(
                      text: dia,
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w900,
                        fontSize: 35,
                      ),
                      children: [
                        TextSpan(
                          text: " $mes",
                          style: TextStyle(
                            letterSpacing: -1,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Positioned(
          top: 200,
          //bottom: 50,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('App-Category')
                      .snapshots(),
              builder: (context, snapshot) {
                return ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: "Proximos Talleres ",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            children: [
                              TextSpan(
                                text: " 4",
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    todasLasFechas(),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Container todasLasFechas() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      height: 1310,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Taller').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot documenet = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  documenet.data() as Map<String, dynamic>;
              String nombre = data['mes'];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data['fecha'],
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    color: Colors.grey.withValues(alpha: 100),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 160,
                          child: Text(
                            data['nomTaller'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Iconsax.location,
                              size: 20,
                              color: kprimaryColor,
                            ),
                            SizedBox(width: 5),
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 160,
                              child: Text(
                                data['direccion'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Iconsax.user, size: 20, color: kprimaryColor),
                            SizedBox(width: 5),
                            Text(
                              data['couch'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
