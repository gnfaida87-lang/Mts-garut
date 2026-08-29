import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class MateriPdfViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const MateriPdfViewerPage({super.key, required this.url, required this.title});

  @override
  State<MateriPdfViewerPage> createState() => _MateriPdfViewerPageState();
}

class _MateriPdfViewerPageState extends State<MateriPdfViewerPage> {
  late String _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = _normalizeUrl(widget.url);
  }

  String _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    // Deteksi Google Drive share link dan konversi ke direct download
    final driveMatch = RegExp(
      r'(?:drive\.google\.com/(?:file/d/|open\?id=|uc\?id=|uc\?export=preview&id=))([\w\-_]{10,})',
    ).firstMatch(trimmed);
    if (driveMatch != null) {
      final fileId = driveMatch.group(1)!;
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      ),
      body: SfPdfViewer.network(
        _resolvedUrl,
        onDocumentLoadFailed: (value) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat materi: ${value.description}')),
            );
          }
        },
      ),
    );
  }
}
