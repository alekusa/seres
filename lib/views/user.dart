import 'dart:io';
import 'package:SERES/Provider/user_provider.dart';
import 'package:SERES/Utils/constant.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    hide PlayerState;

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  String? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initFields(UserProvider provider) {
    final user = provider.currentUser;
    final userData = provider.userData;

    _nameController.text = user?.displayName ?? "";
    _addressController.text = userData?['address'] ?? "";
    _phoneController.text = userData?['phone'] ?? "";
    _selectedBirthDate = userData?['birthDate'];
  }

  Future<void> _pickImage(UserProvider provider) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Iconsax.camera),
                  title: const Text('Tomar Foto'),
                  onTap: () async {
                    final result = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    Navigator.pop(context, result);
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.gallery),
                  title: const Text('Galería'),
                  onTap: () async {
                    final result = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    Navigator.pop(context, result);
                  },
                ),
                if (provider.currentUser?.providerData.any(
                      (info) => info.providerId == 'google.com',
                    ) ??
                    false)
                  ListTile(
                    leading: const Icon(Icons.login, color: Colors.blue),
                    title: const Text('Usar foto de Google'),
                    onTap: () async {
                      Navigator.pop(context);
                      await provider.syncWithGooglePhoto();
                    },
                  ),
              ],
            ),
          ),
    );

    if (image != null) {
      await provider.uploadProfileImage(File(image.path));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kprimaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: kbackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? "Editar Perfil" : "Mi Perfil",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Iconsax.logout, color: Colors.black),
              onPressed: () => _showLogoutDialog(userProvider),
            )
          else
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(userProvider),
            const SizedBox(height: 20),
            if (_isEditing)
              _buildEditForm(userProvider)
            else ...[
              if (userProvider.isVip)
                _buildVipContent(userProvider)
              else
                _buildLockedContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserProvider provider) {
    final user = provider.currentUser;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: kprimaryColor.withOpacity(0.1),
                  backgroundImage:
                      user?.photoURL != null && user!.photoURL!.isNotEmpty
                          ? NetworkImage(user.photoURL!)
                          : null,
                  child:
                      user?.photoURL == null || user!.photoURL!.isEmpty
                          ? Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ??
                                "U",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: kprimaryColor,
                            ),
                          )
                          : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickImage(provider),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kprimaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Iconsax.camera,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            user?.displayName ?? "Usuario",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? "",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          if (provider.isVip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Iconsax.crown, size: 16, color: Colors.amber),
                  SizedBox(width: 6),
                  Text(
                    "MIEMBRO PREMIUM",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 15),
          if (!_isEditing)
            ElevatedButton.icon(
              onPressed: () {
                _initFields(provider);
                setState(() => _isEditing = true);
              },
              icon: const Icon(Iconsax.edit, size: 18),
              label: const Text("Editar Perfil"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditForm(UserProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información Personal",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: "Nombre a mostrar",
              icon: Iconsax.user,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? "Ingresa tu nombre"
                          : null,
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: _buildTextField(
                  controller: TextEditingController(text: _selectedBirthDate),
                  label: "Fecha de nacimiento (Opcional)",
                  icon: Iconsax.calendar_1,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _addressController,
              label: "Dirección (Opcional)",
              icon: Iconsax.location,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _phoneController,
              label: "Teléfono (Opcional)",
              icon: Iconsax.mobile,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await provider.updateProfile(
                      displayName: _nameController.text,
                      birthDate: _selectedBirthDate,
                      address: _addressController.text,
                      phone: _phoneController.text,
                    );
                    setState(() => _isEditing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Perfil actualizado correctamente"),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Guardar Cambios",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kprimaryColor, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: kprimaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  void _showLogoutDialog(UserProvider provider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Cerrar Sesión"),
            content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await provider.signOut();
                },
                child: const Text(
                  "Cerrar Sesión",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
