import 'package:SERES/Provider/user_provider.dart';
import 'package:SERES/Utils/constant.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    hide PlayerState;

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Perfil",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout, color: Colors.black),
            onPressed: () async {
              // TODO: Implementar logout desde auth_service si es necesario
              // O mostrar diálogo de confirmación
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header del Usuario
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: kprimaryColor.withOpacity(0.1),
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? "U",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kprimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? "Usuario",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? "",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 5),
                      // Badge de VIP
                      if (userProvider.isVip)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Iconsax.crown,
                                size: 14,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "PREMIUM",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Contenido Principal
            if (userProvider.isVip)
              _buildVipContent(userProvider)
            else
              _buildLockedContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedContent() {
    return Container(
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Iconsax.lock, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            "Área Exclusiva",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Esta sección está reservada para alumnos que han completado el curso básico en SERES.\n\nAccede a audios, videos y sesiones de meditación exclusivas.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Acción para contactar o info
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kprimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text("Más Información"),
          ),
        ],
      ),
    );
  }

  Widget _buildVipContent(UserProvider provider) {
    return StreamBuilder<List<ExclusiveContent>>(
      stream: provider.exclusiveContentStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Próximamente contenido exclusivo."),
            ),
          );
        }

        final contents = snapshot.data!;

        // Agrupar por tipo si se desea, o mostrar lista mixta
        // Aquí mostramos lista mixta con iconos distintivos
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(15),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final item = contents[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getColorForType(item.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconForType(item.type),
                    color: _getColorForType(item.type),
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Iconsax.clock, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          item.duration,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => _openContent(context, item),
              ),
            );
          },
        );
      },
    );
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Colors.blue;
      case 'audio':
        return Colors.purple;
      case 'meditation':
        return Colors.teal;
      default:
        return kprimaryColor;
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Iconsax.video;
      case 'audio':
        return Iconsax.music;
      case 'meditation':
        return Icons.self_improvement;
      default:
        return Iconsax.play;
    }
  }

  void _openContent(BuildContext context, ExclusiveContent item) {
    if (item.type == 'video' || item.contentUrl.contains('youtube')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => YoutubePlayerScreen(
                videoId: YoutubePlayer.convertUrlToId(item.contentUrl) ?? '',
                title: item.title,
                description: item.description,
              ),
        ),
      );
    } else if (item.type == 'audio' || item.type == 'meditation') {
      // Aquí podrías reutilizar tu lógica de audio player existente
      // O mostrar un reproductor simple
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SimpleAudioPlayerScreen(
                url: item.contentUrl,
                title: item.title,
              ),
        ),
      );
    }
  }
}

// Pantalla simple para YouTube
class YoutubePlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String description;

  const YoutubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.description,
  });

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Reproductor'),
      ),
      body: Column(
        children: [
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: kprimaryColor,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(widget.description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Pantalla simple para Audio (Reutilizando lógica básica)
class SimpleAudioPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const SimpleAudioPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<SimpleAudioPlayerScreen> createState() =>
      _SimpleAudioPlayerScreenState();
}

class _SimpleAudioPlayerScreenState extends State<SimpleAudioPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _player.setSourceUrl(widget.url);

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.music_circle, size: 100, color: kprimaryColor),
            const SizedBox(height: 30),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Slider(
              min: 0,
              max: _duration.inSeconds.toDouble(),
              value: _position.inSeconds.toDouble(),
              activeColor: kprimaryColor,
              onChanged: (value) async {
                await _player.seek(Duration(seconds: value.toInt()));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position)),
                Text(_formatDuration(_duration)),
              ],
            ),
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 35,
              backgroundColor: kprimaryColor,
              child: IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 35,
                ),
                onPressed: () async {
                  if (_isPlaying) {
                    await _player.pause();
                  } else {
                    await _player.resume();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
