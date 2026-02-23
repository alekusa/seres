import 'package:flutter/material.dart';

class BannerToExplore extends StatefulWidget {
  final VoidCallback? onTap;
  const BannerToExplore({super.key, this.onTap});

  @override
  State<BannerToExplore> createState() => _BannerToExploreState();
}

class _BannerToExploreState extends State<BannerToExplore> {
  // Portada

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xffeff1f7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 32,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Conciencia",
                  style: TextStyle(
                    height: 1.1,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 70, 144, 239),
                  ),
                ),
                Text(
                  "Transformación",
                  style: TextStyle(
                    height: 1.1,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 173, 66),
                  ),
                ),
                Text(
                  "Presencia",
                  style: TextStyle(
                    height: 1.1,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: widget.onTap,
                  child: const Text(
                    "Talleres",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: Image.asset('assets/images/Logo.png'),
          ),
        ],
      ),
    );
  }
}
