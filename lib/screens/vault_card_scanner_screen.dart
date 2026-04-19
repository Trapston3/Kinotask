import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';

import '../providers/vault_provider.dart';

import '../theme/app_theme.dart';
import '../utils/luhn_validator.dart';

class VaultCardScannerScreen extends StatefulWidget {
  const VaultCardScannerScreen({super.key});

  @override
  State<VaultCardScannerScreen> createState() =>
      _VaultCardScannerScreenState();
}

class _VaultCardScannerScreenState extends State<VaultCardScannerScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessing = false;
  String? _validatedNumber;
  String? _errorMsg;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMsg = 'No camera found');
        return;
      }
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(title: const Text('Card Scanner')),
      body: _validatedNumber != null
          ? _buildResult()
          : _cameraReady
              ? _buildScanner()
              : _buildLoading(),
    );
  }

  // ── Loading / error ─────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: _errorMsg != null
          ? Text(_errorMsg!,
              style: const TextStyle(color: AppTheme.subtleGrey),
              textAlign: TextAlign.center)
          : const CircularProgressIndicator(),
    );
  }

  // ── Camera with bounding box ────────────────────────────────────
  Widget _buildScanner() {
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),

        // Bounding box overlay
        Positioned.fill(
          child: CustomPaint(
            painter: _CardBoundingBoxPainter(),
          ),
        ),

        // Instruction text
        const Positioned(
          top: 40,
          left: 24,
          right: 24,
          child: Text(
            'Align your card within the frame',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 8)],
            ),
          ),
        ),

        // Scan button
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _isProcessing ? null : _scanCard,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isProcessing
                      ? AppTheme.subtleGrey
                      : AppTheme.accentBlue,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentBlue.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white),
                      )
                    : const Icon(Icons.document_scanner_rounded,
                        color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Validated result ────────────────────────────────────────────
  Widget _buildResult() {
    final formatted = _formatCardNumber(_validatedNumber!);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.islandSurface,
            borderRadius: BorderRadius.circular(AppTheme.islandRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF34C759).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF34C759), size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Card Validated',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Luhn check passed ✓',
                  style: TextStyle(color: AppTheme.subtleGrey)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.pitchBlack,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  formatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _validatedNumber = null;
                        _errorMsg = null;
                      }),
                      child: const Text('Scan Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final vault = context.read<VaultProvider>();
                        final box = await vault.openEncryptedBox('vault_cards');
                        await box.add({
                          'bank': 'Scanned Card',
                          'last4': _validatedNumber!.substring(_validatedNumber!.length - 4),
                          'holder': 'Unknown',
                          'number': _validatedNumber, // full number saved securely
                        });
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Card saved to vault'),
                              backgroundColor: AppTheme.islandSurface,
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── OCR scan ────────────────────────────────────────────────────
  Future<void> _scanCard() async {
    if (_cameraController == null || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });

    try {
      final file = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final result = await _textRecognizer.processImage(inputImage);

      // Collect all text from recognized blocks.
      final fullText =
          result.blocks.map((b) => b.text).join(' ');

      // Extract candidates.
      final candidates = LuhnValidator.extractCandidates(fullText);

      // Find the first valid one.
      for (final candidate in candidates) {
        if (LuhnValidator.validate(candidate)) {
          setState(() {
            _validatedNumber = candidate;
            _isProcessing = false;
          });
          return;
        }
      }

      // No valid card found.
      setState(() {
        _isProcessing = false;
        _errorMsg = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No valid card number found. Try again with better alignment.'),
            backgroundColor: AppTheme.islandSurface,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMsg = e.toString();
      });
    }
  }

  String _formatCardNumber(String number) {
    final buf = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(number[i]);
    }
    return buf.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Bounding box painter — draws a card-shaped frame on the camera feed.
// ═══════════════════════════════════════════════════════════════════════

class _CardBoundingBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.saveLayer(area, Paint());

    // Semi-transparent overlay
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(area, overlay);

    // Card-shaped cut-out (standard card ratio ≈ 1.586)
    const cardRatio = 1.586;
    final cardWidth = size.width * 0.85;
    final cardHeight = cardWidth / cardRatio;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: cardWidth,
        height: cardHeight,
      ),
      const Radius.circular(16),
    );

    // Clear the card area
    canvas.drawRRect(
      cardRect,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill,
    );

    // Draw border
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = AppTheme.accentBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Corner accents
    _drawCornerAccents(canvas, cardRect);

    canvas.restore();
  }

  void _drawCornerAccents(Canvas canvas, RRect rect) {
    const len = 24.0;
    final paint = Paint()
      ..color = AppTheme.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final r = rect.outerRect;

    // Top-left
    canvas.drawLine(Offset(r.left, r.top + len), r.topLeft, paint);
    canvas.drawLine(r.topLeft, Offset(r.left + len, r.top), paint);

    // Top-right
    canvas.drawLine(
        Offset(r.right, r.top + len), r.topRight, paint);
    canvas.drawLine(
        r.topRight, Offset(r.right - len, r.top), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(r.left, r.bottom - len), r.bottomLeft, paint);
    canvas.drawLine(
        r.bottomLeft, Offset(r.left + len, r.bottom), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(r.right, r.bottom - len), r.bottomRight, paint);
    canvas.drawLine(
        r.bottomRight, Offset(r.right - len, r.bottom), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
