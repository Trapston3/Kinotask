import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/vault_provider.dart';

class VaultDocumentsScreen extends StatefulWidget {
  const VaultDocumentsScreen({super.key});

  @override
  State<VaultDocumentsScreen> createState() => _VaultDocumentsScreenState();
}

class _VaultDocumentsScreenState extends State<VaultDocumentsScreen> {
  late Box _box;
  bool _isInit = false;
  List<_DocumentEntry> _documents = [];

  @override
  void initState() {
    super.initState();
    final vault = context.read<VaultProvider>();
    _initHive(vault);
  }

  Future<void> _initHive(VaultProvider vault) async {
    _box = await vault.openEncryptedBox('vault_documents');
    if (!mounted) return;
    _loadEntries();
  }

  void _loadEntries() {
    final list = _box.values.toList();
    if (list.isEmpty) {
      _documents = List.from(_defaultDocuments);
    } else {
      final keys = _box.keys.toList();
      final validEntries = <_DocumentEntry>[];
      for (var i = 0; i < list.length; i++) {
        final e = list[i];
        final k = keys[i];
        if (e is Map) {
          validEntries.add(_DocumentEntry(
            key: k,
            name: e['name']?.toString() ?? 'Unknown',
            date: e['date']?.toString() ?? '',
            icon: Icons.insert_drive_file_rounded,
            color: AppTheme.accentBlue,
            pages: e['pages'] is int ? e['pages'] : 1,
          ));
        }
      }
      _documents = validEntries;
    }
    setState(() => _isInit = true);
  }

  void _showUploadActionSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Add Document'),
        message: const Text('Choose how you want to add a document to your vault.'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const _DocumentCaptureScreen()),
              );
              if (result != null) {
                final now = DateTime.now();
                await _box.add({
                  'name': 'Scan ${now.millisecondsSinceEpoch}',
                  'date': '${now.month}/${now.day}/${now.year}',
                  'pages': 1,
                  'path': result,
                });
                _loadEntries();
              }
            },
            child: const Text('Scan Document'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _uploadFile();
            },
            child: const Text('Choose from Storage'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final appDir = await getApplicationDocumentsDirectory();
    final newPath = '${appDir.path}/${result.files.single.name}';
    await file.copy(newPath);

    final now = DateTime.now();
    await _box.add({
      'name': result.files.single.name,
      'date': '${now.month}/${now.day}/${now.year}',
      'pages': 1,
      'path': newPath,
    });
    _loadEntries();
  }

  static const List<_DocumentEntry> _defaultDocuments = [
    _DocumentEntry(
      name: 'Passport Scan',
      date: 'Oct 15, 2025',
      icon: Icons.badge_rounded,
      color: Color(0xFFFF9F0A),
      pages: 2,
    ),
    _DocumentEntry(
      name: 'Health Insurance Card',
      date: 'Sep 3, 2025',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF34C759),
      pages: 1,
    ),
    _DocumentEntry(
      name: 'Lease Agreement',
      date: 'Aug 20, 2025',
      icon: Icons.home_rounded,
      color: Color(0xFF5AC8FA),
      pages: 12,
    ),
    _DocumentEntry(
      name: "Driver's License",
      date: 'Jul 10, 2025',
      icon: Icons.directions_car_rounded,
      color: Color(0xFFBF5AF2),
      pages: 2,
    ),
    _DocumentEntry(
      name: 'Tax Return 2024',
      date: 'Apr 14, 2025',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFFF453A),
      pages: 8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadActionSheet,
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.upload_file_rounded, color: Colors.white),
      ),
      body: !_isInit ? const Center(child: CircularProgressIndicator()) : ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        itemCount: _documents.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final doc = _documents[i];
          return GestureDetector(
            onTap: () => _showPreviewSheet(doc),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.islandSurface,
                borderRadius: BorderRadius.circular(AppTheme.islandRadius),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: doc.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(doc.icon, color: doc.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${doc.pages} page${doc.pages > 1 ? 's' : ''} · ${doc.date}',
                            style: const TextStyle(
                                color: AppTheme.subtleGrey, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.subtleGrey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  void _showPreviewSheet(_DocumentEntry doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.pitchBlack,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.subtleGrey, borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Text(doc.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: doc.key != null && _box.getAt(_box.values.toList().indexOf(_box.get(doc.key)))?['path'] != null
                        ? InteractiveViewer(
                            child: Image.file(
                              File(_box.getAt(_box.values.toList().indexOf(_box.get(doc.key)))['path']),
                              fit: BoxFit.contain,
                            ),
                          )
                        : Center(child: Icon(doc.icon, size: 120, color: doc.color.withValues(alpha: 0.2))),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DocumentCaptureScreen extends StatefulWidget {
  const _DocumentCaptureScreen();

  @override
  State<_DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<_DocumentCaptureScreen> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.max, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;
    final file = await _controller!.takePicture();
    if (mounted) Navigator.pop(context, file.path);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          // Edge detection hint overlay
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentBlue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.camera, color: Colors.white, size: 80),
              onPressed: _takePicture,
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _DocumentEntry {
  const _DocumentEntry({
    this.key,
    required this.name,
    required this.date,
    required this.icon,
    required this.color,
    required this.pages,
  });

  final dynamic key;
  final String name;
  final String date;
  final IconData icon;
  final Color color;
  final int pages;
}
