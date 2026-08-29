import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../services/santri_service.dart';
import 'materi_pdf_viewer_page.dart';

class MateriSantriPage extends StatefulWidget {
  const MateriSantriPage({super.key});

  @override
  State<MateriSantriPage> createState() => _MateriSantriPageState();
}

class _MateriSantriPageState extends State<MateriSantriPage> {
  final _service = SantriService();
  List<Map<String, dynamic>> _grouped = [];
  bool _loading = true;
  Map<String, dynamic>? _selectedMapel;

  @override
  void initState() {
    super.initState();
    _loadMateri();
  }

  Future<void> _loadMateri() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getMateriGrouped();
      if (mounted) {
        setState(() {
          _grouped = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPdf(String url, String judul) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MateriPdfViewerPage(url: url, title: judul),
      ),
    );
  }

  void _playVideo(String url, String judul) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link video tidak valid')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _VideoPlayerDialog(videoId: videoId, judul: judul),
    );
  }

  void _selectMapel(Map<String, dynamic> mapel) {
    setState(() => _selectedMapel = mapel);
  }

  void _backToList() {
    setState(() => _selectedMapel = null);
  }

  @override
  Widget build(BuildContext context) {
    // Level 2: Detail materi per mapel
    if (_selectedMapel != null) {
      return _buildMateriDetail(_selectedMapel!);
    }

    // Level 1: Daftar mapel
    return _buildMapelList();
  }

  // ═══════════════════════════════════════════════
  // LEVEL 1: DAFTAR MAPEL
  // ═══════════════════════════════════════════════

  Widget _buildMapelList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.menu_book, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text('Materi Pelajaran', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryDark,
              )),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _grouped.isEmpty
                  ? const Center(child: Text('Belum ada materi'))
                  : RefreshIndicator(
                      onRefresh: _loadMateri,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _grouped.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final mapel = _grouped[i];
                          final jumlahMateri = (mapel['materi_list'] as List?)?.length ?? 0;
                          final hasVideo = (mapel['materi_list'] as List?)
                              ?.any((m) => m['link_youtube'] != null) ?? false;

                          return Card(
                            child: InkWell(
                              onTap: () => _selectMapel(mapel),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                      child: const Icon(Icons.book, color: AppTheme.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(mapel['mapel_nama'] ?? '-',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text('${mapel['guru_nama'] ?? '-'}',
                                              style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('$jumlahMateri Materi',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
                                        ),
                                        if (hasVideo) ...[
                                          const SizedBox(height: 4),
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.play_circle_outline, size: 12, color: Colors.red),
                                              SizedBox(width: 2),
                                              Text('Video', style: TextStyle(fontSize: 10, color: Colors.red)),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, color: AppTheme.grey400),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // LEVEL 2: DETAIL MATERI PER MAPEL
  // ═══════════════════════════════════════════════

  Widget _buildMateriDetail(Map<String, dynamic> mapel) {
    final materiList = (mapel['materi_list'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: _backToList,
                icon: const Icon(Icons.arrow_back, size: 20),
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mapel['mapel_nama'] ?? '-',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                    Text(mapel['guru_nama'] ?? '-',
                        style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // List materi
        Expanded(
          child: materiList.isEmpty
              ? const Center(child: Text('Belum ada materi'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: materiList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildMateriCard(materiList[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildMateriCard(Map<String, dynamic> m) {
    final hasYoutube = m['link_youtube'] != null && (m['link_youtube'] as String).isNotEmpty;
    final hasDrive = m['link_url'] != null && (m['link_url'] as String).isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pertemuan badge + Judul
            Row(
              children: [
                if (m['pertemuan'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Pertemuan ${m['pertemuan']}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m['judul'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
            if (m['deskripsi'] != null && (m['deskripsi'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(m['deskripsi'], style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
            ],
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                // YouTube button
                if (hasYoutube)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _playVideo(m['link_youtube'], m['judul'] ?? 'Video'),
                      icon: const Icon(Icons.play_circle_outline, size: 16),
                      label: const Text('Putar Video', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                if (hasYoutube && hasDrive) const SizedBox(width: 8),
                if (hasDrive)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openPdf(m['link_url'], m['judul'] ?? 'Materi'),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Lihat Materi', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final String videoId;
  final String judul;

  const _VideoPlayerDialog({required this.videoId, required this.judul});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.judul,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
