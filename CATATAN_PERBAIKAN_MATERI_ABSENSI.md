# Catatan Perbaikan: Fitur Materi & Absensi (Santri)

> **Tanggal:** 2026-08-29
> **Tujuan catatan:** Rangkuman perbaikan/peningkatan yang sudah dilakukan pada sistem MA Persis Garut (MA), agar bisa **diterapkan ulang pada sistem tingkat MTS** yang strukturnya sama.
>
> Modul yang diubah:
> 1. **Halaman Materi (Santri)** — video diputar inline di aplikasi + preview PDF di halaman (tidak lagi pindah ke YouTube/Google Drive eksternal).
> 2. **Halaman Absensi (Santri)** — penambahan filter **Tanggal** di samping filter Bulan & Tahun.

---

## Daftar Isi
1. [Ringkasan Perubahan](#1-ringkasan-perubahan)
2. [Dependency yang Ditambahkan](#2-dependency-yang-ditambahkan)
3. [Perbaikan 1: Video Inline (YoutubePlayer)](#3-perbaikan-1-video-inline-youtubeplayer)
4. [Perbaikan 2: Preview PDF di Halaman](#4-perbaikan-2-preview-pdf-di-halaman)
5. [Perbaikan 3: Filter Tanggal Absensi (Frontend)](#5-perbaikan-3-filter-tanggal-absensi-frontend)
6. [Perbaikan 4: Filter Tanggal Absensi (Backend)](#6-perbaikan-4-filter-tanggal-absensi-backend)
7. [Cara Menerapkan di Sistem MTS](#7-cara-menerapkan-di-sistem-mts)

---

## 1. Ringkasan Perubahan

### Sebelum
- **Video:** tombol "Putar Video" memanggil `url_launcher` → membuka aplikasi/browser **eksternal** (YouTube).
- **Materi:** tombol "Lihat Materi" memanggil `url_launcher` → membuka Google Drive **eksternal**.
- **Absensi:** hanya ada filter **Bulan** dan **Tahun**.

### Sesudah
- **Video:** diputar **inline** di dalam aplikasi (dialog player `YoutubePlayer`).
- **Materi:** ditampilkan **preview PDF di dalam halaman** (viewer `syncfusion_flutter_pdfviewer`), termasuk dukungan otomatis untuk link sharing Google Drive.
- **Absensi:** ada filter **Tanggal + Bulan + Tahun**.

---

## 2. Dependency yang Ditambahkan

Tambahkan di `frontend/pubspec.yaml` (bagian `dependencies`):

```yaml
dependencies:
  # ... dependency yang sudah ada ...
  youtube_player_flutter: ^9.1.3
  syncfusion_flutter_pdfviewer: ^31.1.19
```

Lalu jalankan di folder `frontend/`:

```powershell
flutter pub get
```

> Contoh menjalankan `flutter pub add`:
> ```powershell
> flutter pub add youtube_player_flutter syncfusion_flutter_pdfviewer
> ```

---

## 3. Perbaikan 1: Video Inline (YoutubePlayer)

**File:** `frontend/lib/features/santri/materi/materi_santri_page.dart`
**Import:** ganti `url_launcher` → `youtube_player_flutter`.

### 3a. Import
```dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../services/santri_service.dart';
import 'materi_pdf_viewer_page.dart';   // halaman viewer PDF (lihat bagian 4)
```

### 3b. Ganti method `_openUrl` dengan dua method baru
```dart
// HAPUS method lama ini:
// Future<void> _openUrl(String url) async {
//   final uri = Uri.parse(url);
//   if (await canLaunchUrl(uri)) {
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }
// }

// TAMBAHKAN:
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
```

### 3c. Perbarui tombol di dalam `_buildMateriCard`
```dart
// Tombol YouTube (sebelumnya: onPressed: () => _openUrl(m['link_youtube']))
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

// Tombol Materi (sebelumnya: onPressed: () => _openUrl(m['link_url']))
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
```

### 3d. Tambahkan widget dialog player di bagian bawah file (di luar class `_MateriSantriPageState`)
```dart
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
```

---

## 4. Perbaikan 2: Preview PDF di Halaman

**File baru:** `frontend/lib/features/santri/materi/materi_pdf_viewer_page.dart`

Halaman ini menampilkan PDF langsung di dalam aplikasi dengan `syncfusion_flutter_pdfviewer`, termasuk konversi otomatis dari link sharing Google Drive → direct download.

> **Penting:** Package PDF ini memakai `SfPdfViewer.network`, yang menangani loading, error, dan pagination secara otomatis. (TIDAK memakai `pdfx`/`photo_view` — keduanya bermasalah dengan Flutter SDK 3.32.1 karena konflik `vector_math 2.1.4`.)

```dart
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
```

---

## 5. Perbaikan 3: Filter Tanggal Absensi (Frontend)

**File:** `frontend/lib/features/santri/services/santri_service.dart`
Tambahkan parameter `tanggal` pada method `getAbsensi`:

```dart
Future<Map<String, dynamic>> getAbsensi({
  String? bulan,
  String? tahun,
  String? tanggal,
  int page = 1,
  int perPage = 20,
}) async {
  final queryParams = <String, String>{
    'page': page.toString(),
    'per_page': perPage.toString(),
  };
  if (tanggal != null && tanggal.isNotEmpty) queryParams['tanggal'] = tanggal;
  if (bulan != null) queryParams['bulan'] = bulan;
  if (tahun != null) queryParams['tahun'] = tahun;
  final response = await ApiClient.get('/siswa/absensi', queryParams: queryParams);
  return response['data'] as Map<String, dynamic>;
}
```

**File:** `frontend/lib/features/santri/absensi/absensi_santri_page.dart`

```dart
// 1) Tambahkan state + method pemilih tanggal (setelah variabel _tahun):
String _bulan = DateTime.now().month.toString();
String _tahun = DateTime.now().year.toString();
String? _tanggal;

Future<void> _pickTanggal() async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(now.year - 3),
    lastDate: DateTime(now.year, 12, 31),
  );
  if (picked != null) {
    setState(() {
      _tanggal = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
    _loadAbsensi();
  }
}

// 2) Kirim tanggal di dalam _loadAbsensi:
final result = await _service.getAbsensi(
  tanggal: _tanggal,
  bulan: _bulan,
  tahun: _tahun,
  page: _page,
);

// 3) Tambahkan UI filter tanggal. Sisipkan tepat SETELAH blok filter tahun
//    (sebelum `const SizedBox(height: 16)` yang menuju bagian Data):
SizedBox(
  width: double.infinity,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: OutlinedButton.icon(
      onPressed: _pickTanggal,
      icon: const Icon(Icons.event, size: 18),
      label: Text(
        _tanggal == null
            ? 'Filter Tanggal (Semua)'
            : 'Tanggal: $_tanggal',
        style: const TextStyle(fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),
  ),
),
if (_tanggal != null)
  Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.only(right: 16),
      child: TextButton.icon(
        onPressed: () {
          setState(() => _tanggal = null);
          _loadAbsensi();
        },
        icon: const Icon(Icons.clear, size: 16),
        label: const Text('Reset Tanggal', style: TextStyle(fontSize: 12)),
      ),
    ),
  ),
```

> **Catatan logika:** jika `tanggal` diisi, backend mengabaikan `bulan`/`tahun` (tanggal lebih spesifik).

---

## 6. Perbaikan 4: Filter Tanggal Absensi (Backend)

**File:** `backend/src/routes/siswa/absensi.ts`
Tambahkan dukungan query param `tanggal` dengan prioritas di atas bulan/tahun:

```ts
import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

export async function handleAbsensi(
  env: Env,
  user: UserPayload,
  url: URL
): Promise<Response> {
  const bulan = url.searchParams.get('bulan');
  const tahun = url.searchParams.get('tahun');
  const tanggal = url.searchParams.get('tanggal');
  const page = parseInt(url.searchParams.get('page') ?? '1');
  const perPage = parseInt(url.searchParams.get('per_page') ?? '20');
  const offset = (page - 1) * perPage;

  // Hitung total
  let countQuery = 'SELECT COUNT(*) as total FROM absensi_siswa WHERE siswa_id = ?';
  const countParams: any[] = [user.siswa_id];

  if (tanggal) {
    countQuery += " AND tanggal = ?";
    countParams.push(tanggal);
  } else if (bulan && tahun) {
    countQuery += " AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?";
    countParams.push(bulan.padStart(2, '0'), tahun);
  }

  const { results: countResult } = await env.DB.prepare(countQuery).bind(...countParams).all();
  const total = (countResult[0] as any).total;

  // Ambil data
  let dataQuery = `
    SELECT a.*, mp.nama as mapel_nama
    FROM absensi_siswa a
    LEFT JOIN mata_pelajaran mp ON a.mata_pelajaran_id = mp.id
    WHERE a.siswa_id = ?
  `;
  const dataParams: any[] = [user.siswa_id];

  if (tanggal) {
    dataQuery += " AND a.tanggal = ?";
    dataParams.push(tanggal);
  } else if (bulan && tahun) {
    dataQuery += " AND strftime('%m', a.tanggal) = ? AND strftime('%Y', a.tanggal) = ?";
    dataParams.push(bulan.padStart(2, '0'), tahun);
  }

  dataQuery += ' ORDER BY a.tanggal DESC LIMIT ? OFFSET ?';
  dataParams.push(perPage, offset);

  const { results } = await env.DB.prepare(dataQuery).bind(...dataParams).all();

  // Hitung statistik
  let statsQuery = `
    SELECT status, COUNT(*) as jumlah
    FROM absensi_siswa
    WHERE siswa_id = ?
  `;
  const statsParams: any[] = [user.siswa_id];

  if (tanggal) {
    statsQuery += " AND tanggal = ?";
    statsParams.push(tanggal);
  } else if (bulan && tahun) {
    statsQuery += " AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?";
    statsParams.push(bulan.padStart(2, '0'), tahun);
  }

  statsQuery += ' GROUP BY status';

  const { results: stats } = await env.DB.prepare(statsQuery).bind(...statsParams).all();

  const statistik: Record<string, number> = {};
  for (const row of stats) {
    statistik[row.status as string] = row.jumlah as number;
  }

  return success({
    data: results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
    statistik,
  });
}
```

---

## 7. Cara Menerapkan di Sistem MTS

> Struktur sistem MTS diasumsikan sama: Flutter frontend (`frontend/`) + Cloudflare Workers backend (`backend/`) dengan route siswa.

1. **Tambahkan dependency** di `frontend/pubspec.yaml` lalu `flutter pub get` (lihat [bagian 2](#2-dependency-yang-ditambahkan)).
2. **Salin file baru:** `frontend/lib/features/santri/materi/materi_pdf_viewer_page.dart` (lihat [bagian 4](#4-perbaikan-2-preview-pdf-di-halaman)).
3. **Perbarui file:** `frontend/lib/features/santri/materi/materi_santri_page.dart` (lihat [bagian 3](#3-perbaikan-1-video-inline-youtubeplayer)) — pastikan path import menyesuaikan struktur MTS.
4. **Perbarui file:** `frontend/lib/features/santri/services/santri_service.dart` (lihat [bagian 5](#5-perbaikan-3-filter-tanggal-absensi-frontend)).
5. **Perbarui file:** `frontend/lib/features/santri/absensi/absensi_santri_page.dart` (lihat [bagian 5](#5-perbaikan-3-filter-tanggal-absensi-frontend)).
6. **Perbarui backend:** `backend/src/routes/siswa/absensi.ts` (lihat [bagian 6](#6-perbaikan-4-filter-tanggal-absensi-backend)).
7. **Verifikasi:**
   - Frontend: `flutter analyze` (harus "No issues found!").
   - Backend: `npm run typecheck` di folder `backend` (harus sukses tanpa error).
8. **Uji manual:**
   - Buka halaman Materi santri → "Putar Video" (video play di dialog, tidak pindah aplikasi) dan "Lihat Materi" (PDF tampil di halaman).
   - Buka halaman Absensi santri → pilih tanggal via date picker, pastikan riwayat & statistik sesuai tanggal tersebut.

---

## Catatan Tambahan

- **Format tanggal** yang dikirim query adalah `YYYY-MM-DD` (mis. `2026-08-29`), menyesuaikan format kolom `tanggal` di SQLite.
- **Google Drive** link yang didukung otomatis dikonversi: share link (`/file/d/...`, `open?id=`, dll.) → direct download. Untuk file non-Drive, link URL langsung bisa digunakan selama mengembalikan bytes PDF.
- Kedua package (`youtube_player_flutter`, `syncfusion_flutter_pdfviewer`) **kompatibel web + mobile**, jadi aman untuk deploy web (Cloudflare Pages) maupun mobile.
- **Catatan lisensi:** `syncfusion_flutter_pdfviewer` menampilkan notice/watermark trial di versi komunitas. Jika Anda memiliki lisensi Syncfusion, panggil `SyncfusionLicense.registerLicense('<kunci>')` di awal aplikasi (`main()`) untuk menghilangkannya.
