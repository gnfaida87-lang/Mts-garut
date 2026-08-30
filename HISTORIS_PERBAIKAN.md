# Historis Perbaikan — Sistem Informasi MTs Persis Garut (Frontend Flutter)

> **Sifat perubahan:** Murni lapisan UI & error handling. **TIDAK menyentuh database, TIDAK mengubah alur kerja/logika/urutan request/pesan sukses.**
> **Verifikasi:** `flutter analyze` = **No issues found!** (seluruh perubahan).
>
> **Ruang lingkup dokumen:** Kepala Sekolah (KS), Guru BK, Musyrifah, Santri, Wakil Kurikulum, dan Admin.

---

## Daftar Isi
1. [Pola Perbaikan yang Digunakan](#1-pola-perbaikan-yang-digunakan)
2. [Modul Kepala Sekolah](#2-modul-kepala-sekolah)
3. [Modul Guru BK](#3-modul-guru-bk)
4. [Modul Musyrifah](#4-modul-musyrifah)
5. [Modul Santri](#5-modul-santri)
6. [Modul Wakil Kurikulum](#6-modul-wakil-kurikulum)
7. [Modul Admin](#7-modul-admin)
8. [Yang Sengaja Dibiarkan](#8-yang-sengaja-dibiarkan)
9. [Lampiran: Diff Per Modul](#9-lampiran-diff-per-modul)

---

## 1. Pola Perbaikan yang Digunakan

Ada **dua kategori** perbaikan yang diterapkan konsisten di seluruh modul.

### 1a. Error handling diam → feedback ramah

Mengubah `catch (_)` yang diam/swallowed menjadi `catch (e)` yang menampilkan pesan ramah via helper bersama `AppUtils.handleError`.

**Sebelum:**
```dart
} catch (_) {
  debugPrint('[nama_file.dart] error caught');
}
```

**Sesudah:**
```dart
} catch (e) {
  if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data ...');
}
```

Varian lain yang juga diubah:
- `catch (_) { _data = []; }` → `catch (e) { _data = []; if (mounted) AppUtils.handleError(...); }`
- SnackBar manual `ScaffoldMessenger...showSnackBar(SnackBar(content: Text('Gagal: $e')))` → `AppUtils.handleError(...)` dengan `message` yang kontekstual.
- `.then((res) {...})` tanpa penanganan error → ditambah `.catchError((e) { if (mounted) AppUtils.handleError(...); })`.

**Catatan lint `use_build_context_synchronously`:** pada callback one-off (mis. `onChanged` dropdown) yang memakai `context`, digunakan `context.mounted`; pada method biasa cukup `if (mounted)` karena analyzer bersih.

### 1b. Double AppBar / nested Scaffold (shell-rendered pages)

Halaman yang dirender di dalam `DashboardShell` (`shared/widgets/dashboard_shell.dart`) sudah diberi header oleh shell. Menambahkan `Scaffold`+`AppBar` lagi menghasilkan **double AppBar / nested Scaffold**. Perbaikan: konversi ke `Column` + **header internal** (teks judul + aksi), lalu `Expanded` untuk body.

**Sebelum (double AppBar):**
```dart
return Scaffold(
  appBar: AppBar(
    title: const Text('Judul'),
    automaticallyImplyLeading: false,
    actions: [...],
  ),
  body: _loading
      ? const Center(child: CircularProgressIndicator())
      : ...,
);
```

**Sesudah (Column + header internal):**
```dart
return Column(
  children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Text('Judul',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800)),
          const Spacer(),
          // aksi (tombol refresh/pdf/add/filter) di sini
        ],
      ),
    ),
    Expanded(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ...,
    ),
  ],
);
```

**Kapan Scaffold DIPERTAHANKAN (bukan nested):**
- Halaman yang dipakai `Navigator.pop` di AppBar leading / dibuka sebagai **root/fullscreen** (mis. `scan_qr_musyrifah_page.dart`, `jadwal_program_page.dart`, `materi_pdf_viewer_page.dart`).
- Dashboard role (`dashboard_page_ks`, `dashboard_page_wk`, `dashboard_musyrifah`) diubah **Scaffold → `Container`** karena shell memberi `Scaffold` body-nya (tanpa AppBar).

---

## 2. Modul Kepala Sekolah

### Error handling (8 file)
| File | Titik yang diperbaiki |
|---|---|
| `kepala_sekolah/absensi/absensi_page_ks.dart` | 3x (data absensi asatidz, daftar kelas, data absensi santri) |
| `kepala_sekolah/bk/bk_page_ks.dart` | 1x (data monitoring) |
| `kepala_sekolah/dashboard/dashboard_page_ks.dart` | 1x (dashboard) |
| `kepala_sekolah/dauroh/dauroh_nilai_page_ks.dart` | 1x (filter nilai at-Ta'wid) |
| `kepala_sekolah/jadwal/jadwal_page_ks.dart` | 1x (data jadwal) |
| `kepala_sekolah/laporan/laporan_page_ks.dart` | 2x (referensi laporan, laporan) |
| `kepala_sekolah/nilai/nilai_page_ks.dart` | 1x (data nilai) |
| `kepala_sekolah/rapor/rapor_page_ks.dart` | 1x (data rapor) |

**Contoh kode (jadwal_page_ks.dart):**
```dart
Future<void> _load() async {
  try {
    final data = await KepalaSekolahService.getJadwal();
    if (!mounted) return;
    _jadwal = data;
  } catch (e) {
    if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data jadwal');
  }
  if (mounted) setState(() => _loading = false);
}
```

### Scaffold fix
- `kepala_sekolah/dauroh/dauroh_nilai_page_ks.dart` — `Scaffold`+`AppBar` → `Column`; judul + aksi cetak PDF dipindah ke header internal `Row` (judul kiri, `IconButton print` kanan), filter/summary/table/pagination dibungkus `Expanded > Column`.

---

## 3. Modul Guru BK

### Error handling (6 file)
| File | Titik yang diperbaiki |
|---|---|
| `guru_bk/bakat_minat/bakat_minat_page.dart` | 3x (daftar kelas, data santri, hapus bakat minat) |
| `guru_bk/dashboard/dashboard_page_bk.dart` | 1x (dashboard) |
| `guru_bk/konseling/konseling_page.dart` | 5x (daftar kelas, data santri, riwayat konseling, simpan jadwal, selesaikan konseling) |
| `guru_bk/monitoring_akademik/monitoring_akademik_page.dart` | 2x (daftar kelas, data monitoring) |
| `guru_bk/pengaduan/pengaduan_page_bk.dart` | 1x (data pengaduan berikutnya) |

**Contoh kode (konseling_page.dart) — SnackBar manual → handleError:**
```dart
// Sebelum
if (ctx.mounted) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
  );
}
// Sesudah
if (ctx.mounted) AppUtils.handleError(ctx, e, message: 'Gagal menyimpan jadwal konseling');
```

Semua file menambah `import '../../../shared/widgets/app_utils.dart';`.

---

## 4. Modul Musyrifah

### Error handling (nilai_dauroh_input_dialog.dart) — 3 titik
| Titik | Pesan |
|---|---|
| `listSurat` | 'Gagal memuat daftar surat' |
| `getJadwal` | 'Gagal memuat jadwal' |
| `listSantriByJadwal` (onChanged dropdown, one-off) | 'Gagal memuat daftar santri' (pakai `context.mounted`) |

**Contoh kode (titik listSantriByJadwal):**
```dart
} catch (e) {
  if (context.mounted) AppUtils.handleError(context, e, message: 'Gagal memuat daftar santri');
}
```

**Tambahan import di `nilai_dauroh_page.dart`:** `app_utils.dart` dan `app_theme.dart` (karena header baru pakai `AppTheme.grey800`).

### Scaffold fix (5 file)
| File | Bentuk |
|---|---|
| `musyrifah/jadwal/jadwal_dauroh_page.dart` | `Scaffold` → `Column`; header Row `'Jadwal Mengajar'` + `_buildHariFilter()` kanan |
| `musyrifah/absensi/riwayat_absensi_page.dart` | `Scaffold` → `Column`; header Row `'Riwayat Absensi'` + `_buildBulanFilter()` kanan |
| `musyrifah/nilai/nilai_dauroh_page.dart` | `Scaffold` → `Column`; header Row `'Nilai at-Ta\'wid'` + aksi PDF & Add; filter container dipindah ke bawah header |
| `musyrifah/dashboard/dashboard_musyrifah_page.dart` | `Scaffold` → `Container` (shell body) |
| `musyrifah/profil/profil_musyrifah_page.dart` | `Scaffold` → `Column` + `const` header (diperbaiki juga lint `prefer_const_constructors`) |

**Dipertahankan Scaffold:** `musyrifah/absensi/scan_qr_musyrifah_page.dart` (root scan).

---

## 5. Modul Santri

Hanya satu halaman nested yang diperbaiki; sisanya memang fullscreen jadi wajar.

### Scaffold fix — `santri/pembayaran/pembayaran_santri_page.dart`
`Scaffold`+`AppBar` → `Column`; header Row `'Idarat al-Madfu\'at'` + `IconButton refresh` kanan; body dibungkus `Expanded`.

**Kode:**
```dart
return Column(
  children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Text('Idarat al-Madfu\'at',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(refresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
    ),
    Expanded(child: _buildBody()),
  ],
);
```

**Dipertahankan Scaffold (fullscreen, punya back):** `dauroh/jadwal_program_page.dart`, `dauroh/hasil_program_page.dart`, `materi/materi_pdf_viewer_page.dart`.

---

## 6. Modul Wakil Kurikulum

### Error handling diubah jadi `AppUtils.handleError`
| File | Titik yang diperbaiki |
|---|---|
| `wakil_kurikulum/absensi/absensi_page.dart` | 5x (absensi asatidz, kelas, absensi santri, kelas rekap, rekap absensi) |
| `wakil_kurikulum/dashboard/dashboard_page.dart` | 1x (dashboard) |
| `wakil_kurikulum/dauroh/dauroh_nilai_page.dart` | 1x (filter nilai at-Ta'wid) |
| `wakil_kurikulum/kenaikan_kelas/kenaikan_kelas_page.dart` | 7x (muat data, referensi, data batch, proses kenaikan, data siswa, simpan/hapus alumni, pengaturan) |
| `wakil_kurikulum/laporan/laporan_page.dart` | 1x (laporan) |
| `wakil_kurikulum/penjadwalan/penjadwalan_page.dart` | 2x (kesiapan mengajar, wali kelas) |
| `wakil_kurikulum/penjadwalan/penjadwalan_dialogs.dart` | 1x (kegiatan tetap) |
| `wakil_kurikulum/nilai/nilai_page.dart` | 1x (referensi nilai) |

**Catatan khusus `nilai_page.dart` (WK):** titik ini diubah menjadi SnackBar `AppUtils`-style manual, bukan `handleError`, karena konteks yang tersedia. Jika ingin konsisten penuh, bisa ditukar ke `AppUtils.handleError`.

---

## 7. Modul Admin

### 7a. Scaffold fix (8 file)
| File | Bentuk |
|---|---|
| `admin/dashboard/dashboard_page.dart` | `Scaffold` → `Container` (shell body) |
| `admin/qr_absensi/qr_absensi_page.dart` | `Scaffold` → `Column`; header teks + `Expanded > SingleChildScrollView` |
| `admin/pengaturan/pengaturan_page.dart` | `Scaffold` → `Column`; header + `Material > TabBar` 7 tab + `Expanded > TabBarView` |
| `admin/master_data/master_data_page.dart` | `Scaffold` → `Column`; header + `Expanded > Row(sidebar, divider, content)` |
| `admin/dauroh/dauroh_page.dart` | `Scaffold` → `Column`; header 'Modul at-Ta\'wid' + `Expanded > Row(sidebar, divider, content)` |
| `admin/absensi/absensi_page.dart` | `Scaffold` → `Column`; header + `Material > TabBar` 5 tab + `Expanded > IndexedStack` |
| `admin/nilai/nilai_page.dart` | `Scaffold` → `Column`; header + `Material > TabBar` 3 tab + `Expanded > IndexedStack` |
| `admin/rapor/rapor_page.dart` | `Scaffold` → `Column`; header + `Material > TabBar` 4 tab + `Expanded > IndexedStack` |

**Pola TabBar yang dipindah (contoh `nilai_page.dart`):**
```dart
return Column(
  children: [
    const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Nilai',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800)),
      ),
    ),
    Material(
      color: Colors.white,
      child: TabBar(controller: _tabCtrl, tabs: const [...same tabs...]),
    ),
    Expanded(
      child: IndexedStack(index: _tabCtrl.index, children: [
        _buildMonitoringTab(),
        const _AnalisisNilaiTab(),
        const _AuditNilaiTab(),
      ]),
    ),
  ],
);
```

### 7b. Error handling (≈20 titik)
| File | Titik yang diperbaiki |
|---|---|
| `admin/absensi/absensi_page.dart` | 5x (data kelas, data absensi, referensi kelas analisis, analisis absensi, riwayat audit) |
| `admin/nilai/nilai_page.dart` | 5x (referensi nilai, data nilai, referensi kelas analisis, analisis nilai, riwayat audit) |
| `admin/rapor/rapor_page.dart` | 4x (data rapor, referensi kelas, analisis rapor, riwayat audit) |
| `admin/master_data/master_data_page.dart` | 3x `.catchError` (tahun ajaran, tingkat, jurusan) |
| `admin/master_data/widgets/mata_pelajaran_form.dart` | 1x (`_loadExistingKelas`) |
| `admin/master_data/widgets/asatidz_form.dart` | 1x (`_loadExistingAssignments` wali) |
| `admin/master_data/widgets/guru_mapel_kelas_form.dart` | 3x (dropdown guru, mapel, kelas) |
| `admin/dauroh/jadwal/jadwal_form_page.dart` | 2x (`_loadReferensi`, `_loadKelasTerkait`) |
| `admin/pengaturan/pengaturan_hak_akses_tab.dart` | 1x (hak akses) |
| `admin/pengaturan/pengaturan_log_tab.dart` | 1x (log aktivitas) |
| `admin/pengaturan/pengaturan_api_keys_tab.dart` | 1x (API keys) |
| `admin/pengaturan/pengaturan_profil_tab.dart` | 2x (profil sekolah, tampilan login) |

**Contoh `.then` → `.catchError` (master_data_page.dart):**
```dart
AdminService.list('tahun-ajaran', page: 1, perPage: 100).then((res) {
  if (mounted) setState(() {
    _data[MasterDataType.tahunAjaran] = (res['items'] as List).cast<Map<String, dynamic>>();
  });
}).catchError((e) {
  if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat tahun ajaran');
});
```

**Contoh fix lengkap (absensi_page.dart, `_load`):**
```dart
} catch (e) {
  _data = [];
  _rekap = null;
  if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data absensi');
}
// lalu
if (mounted) setState(() => _loading = false);
```

---

## 7c. Display Papan Absensi Live — interval polling (Poin A)

**Latar belakang:** Papan Absensi Asatidz Live (`shared/widgets/pages/live_display_page.dart`) dipakai terus-menerus jam operasional **06.30 – 15.00 WIB** (8,5 jam = 510 menit). Awalnya polling tiap **5 detik** → **12 request/menit** ke `/api/public/absensi-hari-ini`. Karena route ini ikut rate limit umum **100 request/menit/IP** (`backend/src/middleware/rate_limit.ts:28-29`), beban display plus traffic lain di IP yang sama berisiko kena **429** → menampilkan "KONEKSI TERPUTUS".

**Catatan penting:** sistem pihak kedua **Al-Idarah** (server terpisah, hanya lewat HTTP/API-key) **tidak tersentuh** oleh perubahan ini. Perubahan hanya di file display MTs sendiri.

**Perubahan (Poin A):**
`frontend/lib/shared/widgets/pages/live_display_page.dart:65`
```diff
-  static const Duration _pollInterval = Duration(seconds: 5);
+  static const Duration _pollInterval = Duration(seconds: 15);
```

**Dampak:**
- Request polling turun dari **12/menit → 4/menit** per display (12% → 4% kuota rate limit 100/menit).
- Delay "live" naik menjadi ≤15 detik (masih wajar untuk papan absensi).
- `flutter analyze` = **No issues found!**.

> **Tertunda (belum diterapkan):** Poin B (skip `/api/public/*` dari `generalRateLimit` di `index.ts`) dan Poin D (tampilkan pesan error asli, simpan `e.message`) — butuh persetujuan terpisah.

---

## 8. Yang Sengaja Dibiarkan

Perbaikan berikut **tidak** dilakukan karena bukan swallowed error atau memang sudah punya feedback yang wajar:

- `_save` dan `_loadDetail` dialog nilai (sudah ada feedback).
- `_formatDate` santri (parsing non-kritis).
- `pengaturan_backup_restore_tab.dart` `_load` debugPrint (sekunder; ada UI error state di utamanya).
- `absensi_monitoring_page.dart`, `nilai_monitoring_page.dart`, `jadwal_list_page.dart` titik sekunder (sudah ada error state di `_load` utama).
- `mata_pelajaran_form.dart` `_loadKelas` & `asatidz_form.dart` L85-92 (sudah ada `_assignmentsLoadError`).
- `_toggleMapelPublish` (sudah SnackBar).

**Temuan audit non-UI yang BELUM diperbaiki (butuh keputusan terpisah):**
- `config/env.dart`: `qrAbsensiToken = 'PPI_ABSENSI_QR_2026'` — hardcoded (keamanan).
- `core/network/api_client.dart`: duplikasi logika refresh token (maintainability).
- URL default `http://localhost:8787` di `env.dart` (konfigurasi).

---

## 9. Lampiran: Diff Per Modul

> Diff di bawah diambil dari `git diff` (state working tree vs HEAD) dan diringkas. Seluruh path relatif terhadap `frontend/`.

### Modul Admin — absensi_page.dart
```diff
@@ _loadKelas @@
-    } catch (_) { debugPrint('[absensi_page.dart] error caught'); }
+    } catch (e) {
+      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data kelas');
+    }

@@ _load @@
-    } catch (_) { _data = []; _rekap = null; }
+    } catch (e) {
+      _data = [];
+      _rekap = null;
+      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data absensi');
+    }

@@ build @@
-    return Scaffold(
-      appBar: AppBar(title: const Text('Absensi'), automaticallyImplyLeading: false,
-        bottom: TabBar(... 5 tab ...),
-      ),
-      body: IndexedStack(index: _tabCtrl.index, children: [
-        _buildMonitoringTab(true),
-        _buildMonitoringTab(false),
-        _buildRekapTab(),
-        const _AnalisisAbsensiTab(),
-        const _AuditAbsensiTab(),
-      ]),
+    return Column(
+      children: [
+        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 4), child: Align(... 'Absensi' ...)),
+        Material(color: Colors.white, child: TabBar(... 5 tab ...)),
+        Expanded(child: IndexedStack(index: _tabCtrl.index, children: [
+          _buildMonitoringTab(true),
+          _buildMonitoringTab(false),
+          _buildRekapTab(),
+          const _AnalisisAbsensiTab(),
+          const _AuditAbsensiTab(),
+        ])),
+      ],
     );
```

*(Pola yang sama berlaku untuk `nilai_page.dart`, `rapor_page.dart`, `pengaturan_page.dart` dengan jumlah tab masing-masing.)*

### Modul Admin — master_data_page.dart (`.then → .catchError`, 3 titik)
```diff
AdminService.list('tahun-ajaran', page: 1, perPage: 100).then((res) {
  if (mounted) setState(() { _data[MasterDataType.tahunAjaran] = ...; });
-});
+}).catchError((e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat tahun ajaran'); });
// tingkat & jurusan: pola identik
```

### Modul Admin — pengaturan part-files
```diff
@@ pengaturan_hak_akses_tab.dart @@
-    } catch (e) { if (mounted) setState(() => _loading = false); }
+    } catch (e) { if (mounted) { setState(() => _loading = false); AppUtils.handleError(context, e, message: 'Gagal memuat hak akses'); } }

@@ pengaturan_log_tab.dart @@
-    } catch (e) { if (mounted) setState(() => _loading = false); }
+    } catch (e) { if (mounted) { setState(() => _loading = false); AppUtils.handleError(context, e, message: 'Gagal memuat log aktivitas'); } }

@@ pengaturan_api_keys_tab.dart @@
-      if (mounted) setState(() => _loading = false);
+      if (mounted) { setState(() => _loading = false); AppUtils.handleError(context, e, message: 'Gagal memuat API keys'); }
```

### Modul Musyrifah — nilai_dauroh_input_dialog.dart (3 titik)
```diff
@@ listSurat @@
-    } catch (_) { debugPrint('[nilai_dauroh_input_dialog.dart] error caught'); }
+    } catch (e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat daftar surat'); }

@@ getJadwal @@
-      } catch (_) { debugPrint('[nilai_dauroh_input_dialog.dart] error caught'); }
+      } catch (e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat jadwal'); }

@@ listSantriByJadwal @@
-                                } catch (_) { debugPrint('[nilai_dauroh_input_dialog.dart] error caught'); }
+                                } catch (e) {
+                                  if (context.mounted) AppUtils.handleError(context, e, message: 'Gagal memuat daftar santri');
+                                }
```

### Modul Guru BK — konseling_page.dart (SnackBar manual → handleError)
```diff
-                    if (ctx.mounted) {
-                      ScaffoldMessenger.of(ctx).showSnackBar(
-                        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
-                      );
-                    }
+                    if (ctx.mounted) AppUtils.handleError(ctx, e, message: 'Gagal menyimpan jadwal konseling');
```

### Modul Wakil Kurikulum — kenaikan_kelas_page.dart (contoh)
```diff
-      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
+      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data');
```

### Modul Santri — pembayaran_santri_page.dart (Scaffold → Column)
```diff
-    return Scaffold(
-      appBar: AppBar(
-        title: const Text('Idarat al-Madfu\'at'),
-        automaticallyImplyLeading: false,
-        actions: [
-          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load(refresh: true), tooltip: 'Refresh'),
-        ],
-      ),
-      body: _buildBody(),
+    return Column(
+      children: [
+        Padding(
+          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
+          child: Row(
+            children: [
+              const Text('Idarat al-Madfu\'at', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800)),
+              const Spacer(),
+              IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load(refresh: true), tooltip: 'Refresh'),
+            ],
+          ),
+        ),
+        Expanded(child: _buildBody()),
+      ],
     );
```

---

## Program / Perintah yang Digunakan

- **Verifikasi statis:** `flutter analyze` (hasil: **No issues found!**).
- **Audit diff:** `git diff` di repo `C:\Mts-garut`.
