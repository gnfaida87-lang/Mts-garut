-- ============================================================
-- SEED DATA — MTs Garut
-- Jalankan dengan: wrangler d1 execute ppi-db --file=src/db/seed.sql
-- Atau: wrangler d1 execute ppi-db-prod --env production --file=src/db/seed.sql
-- ============================================================
-- PERINGATAN: Ganti password default setelah login pertama!
-- ============================================================

-- ============================================================
-- USERS (password: lihat komentar)
-- ============================================================

INSERT OR IGNORE INTO users (username, password_hash, role, is_active) VALUES
  ('admin',           '$2a$10$hhytufYSv9wApOYj1SI4muVIWBQN1L.3txdpxnzB07e7ky/mDz8We', 'admin', 1),                    -- admin123
  ('kepsek',          '$2a$10$rDaF6Co/sW1MtsIMzYCPfOspfr9YrLiCggWWkz5bqNpgjYaRdHOg2', 'kepala_sekolah', 1),         -- kepsek123
  ('wakil_kurikulum', '$2a$10$MDaMQ7j9nmq6qw7cRMIel.53wxB/o.Hd/LpJsf4hm/qfFfpZTWQOO', 'wakil_kurikulum', 1),       -- wk123
  ('guru_bk',          '$2a$10$q/6FecQ6kTbZDbxaULY6IOPR8U5P9lGeZ64QLoGsQL9oIvqhdE.8i', 'guru_bk', 1),              -- bk123
  ('guru',             '$2a$10$qIc07YEw7PA..ycZmimviOwl8KnG2cvDSc.SGyVc0.ouDnyPskXje', 'guru_mapel_wali_kelas', 1); -- guru123

-- ============================================================
-- MASTER DATA — Contoh Awal
-- ============================================================

-- Tahun Ajaran
INSERT OR IGNORE INTO tahun_ajaran (id, nama, tanggal_mulai, tanggal_selesai, is_aktif) VALUES
  (1, '2025/2026', '2025-07-01', '2026-06-30', 0),
  (2, '2026/2027', '2026-07-01', '2027-06-30', 1);

-- Semester
INSERT OR IGNORE INTO semester (id, tahun_ajaran_id, nama, is_aktif) VALUES
  (1, 1, 'Ganjil', 0),
  (2, 1, 'Genap', 0),
  (3, 2, 'Ganjil', 1),
  (4, 2, 'Genap', 0);

-- Jurusan
INSERT OR IGNORE INTO jurusan (id, nama, kode) VALUES
  (1, 'Ilmu Pengetahuan Alam', 'IPA'),
  (2, 'Ilmu Pengetahuan Sosial', 'IPS'),
  (3, 'Bahasa dan Budaya', 'BHS');

-- Tingkat
INSERT OR IGNORE INTO tingkat (id, nama, jenjang) VALUES
  (1, 'VII',   'MTs'),
  (2, 'VIII',  'MTs'),
  (3, 'IX',    'MTs'),
  (4, 'X',     'MA'),
  (5, 'XI',    'MA'),
  (6, 'XII',   'MA');

-- Ruangan
INSERT OR IGNORE INTO ruangan (id, nama, kapasitas) VALUES
  (1, 'Ruang 1', 32),
  (2, 'Ruang 2', 32),
  (3, 'Ruang 3', 32),
  (4, 'Ruang 4', 28),
  (5, 'Ruang 5', 28),
  (6, 'Lab IPA', 24),
  (7, 'Lab Komputer', 24),
  (8, 'Perpustakaan', 20);

-- Mata Pelajaran
INSERT OR IGNORE INTO mata_pelajaran (id, nama, kode) VALUES
  (1,  'Matematika',          'MTK'),
  (2,  'Bahasa Indonesia',    'BIN'),
  (3,  'Bahasa Inggris',      'BING'),
  (4,  'Pendidikan Agama Islam', 'PAI'),
  (5,  'PKN',                 'PKN'),
  (6,  'IPA Terpadu',         'IPA'),
  (7,  'IPS Terpadu',         'IPS'),
  (8,  'Seni Budaya',         'SB'),
  (9,  'Penjasorkes',         'PJOK'),
  (10, 'Prakarya',            'PKWU'),
  (11, 'Fisika',              'FIS'),
  (12, 'Kimia',               'KIM'),
  (13, 'Biologi',             'BIO'),
  (14, 'Ekonomi',             'EKO'),
  (15, 'Sejarah',             'SJRH'),
  (16, 'Geografi',            'GEO'),
  (17, 'Sosiologi',           'SOS'),
  (18, 'Bahasa Arab',         'ARAB'),
  (19, 'Qur''an Hadits',      'QH'),
  (20, 'Akidah Akhlak',       'AA'),
  (21, 'Fiqih',               'FIQ'),
  (22, 'SKI',                 'SKI');

-- Guru
INSERT OR IGNORE INTO guru (id, nip, nama, jenis_kelamin, no_hp, jabatan, status_aktif) VALUES
  (1, '197001012005011001', 'Ahmad Fauzi, S.Pd.',         'L', '081234567890', 'wali_kelas', 1),
  (2, '197501022005012002', 'Siti Nurhaliza, S.Pd.',      'P', '081234567891', 'wali_kelas', 1),
  (3, '198002032005013003', 'Budi Hartono, S.Pd.',        'L', '081234567892', 'guru_mapel', 1),
  (4, '198503042005014004', 'Dewi Sartika, S.Pd.',        'P', '081234567893', 'guru_mapel', 1),
  (5, '199001052005015005', 'Rudi Hermawan, S.Pd.I.',     'L', '081234567894', 'guru_mapel', 1),
  (6, '199102062005016006', 'Fitriani, S.Pd.',            'P', '081234567895', 'guru_mapel', 1),
  (7, '199203072005017007', 'Hendra Gunawan, S.Pd.',      'L', '081234567896', 'guru_bk', 1);

-- Hubungkan user ke data guru
UPDATE users SET guru_id = 1 WHERE username = 'guru';
UPDATE users SET guru_id = 7 WHERE username = 'guru_bk';

-- Kelas
INSERT OR IGNORE INTO kelas (id, nama, tingkat_id, jurusan_id, wali_kelas_id, ruangan_id, tahun_ajaran_id) VALUES
  (1, 'VII-A', 1, null, 1, 1, 2),
  (2, 'VII-B', 1, null, 2, 2, 2),
  (3, 'VIII-A', 2, null, 3, 3, 2),
  (4, 'IX-A', 3, null, 4, 4, 2),
  (5, 'X IPA 1', 4, 1, 5, 5, 2),
  (6, 'X IPS 1', 4, 2, 6, 6, 2);

-- Siswa (contoh 3 per kelas)
INSERT OR IGNORE INTO siswa (id, nis, nisn, nama, jenis_kelamin, kelas_id, tahun_ajaran_id, status) VALUES
  (1,  '24001', '0012345678', 'Abdullah',         'L', 1, 2, 'aktif'),
  (2,  '24002', '0012345679', 'Aisyah',           'P', 1, 2, 'aktif'),
  (3,  '24003', '0012345680', 'Ahmad Rizki',      'L', 1, 2, 'aktif'),
  (4,  '24004', '0012345681', 'Bella Safira',      'P', 2, 2, 'aktif'),
  (5,  '24005', '0012345682', 'Citra Dewi',        'P', 2, 2, 'aktif'),
  (6,  '24006', '0012345683', 'Dimas Ardiansyah',  'L', 2, 2, 'aktif'),
  (7,  '24007', '0012345684', 'Fajar Nugroho',     'L', 3, 2, 'aktif'),
  (8,  '24008', '0012345685', 'Fitri Handayani',    'P', 3, 2, 'aktif'),
  (9,  '24009', '0012345686', 'Gilang Pratama',    'L', 3, 2, 'aktif'),
  (10, '24010', '0012345687', 'Hana Maulida',      'P', 4, 2, 'aktif'),
  (11, '24011', '0012345688', 'Irfan Hakim',       'L', 4, 2, 'aktif'),
  (12, '24012', '0012345689', 'Joko Supriyanto',   'L', 4, 2, 'aktif'),
  (13, '24013', '0012345690', 'Karina Putri',      'P', 5, 2, 'aktif'),
  (14, '24014', '0012345691', 'Lukman Hakim',      'L', 5, 2, 'aktif'),
  (15, '24015', '0012345692', 'Mega Ayu',          'P', 5, 2, 'aktif'),
  (16, '24016', '0012345693', 'Nanda Pratama',     'L', 6, 2, 'aktif'),
  (17, '24017', '0012345694', 'Oktavia Sari',      'P', 6, 2, 'aktif'),
  (18, '24018', '0012345695', 'Putra Ramadan',     'L', 6, 2, 'aktif');

-- ============================================================
-- HAK AKSES DEFAULT
-- ============================================================

INSERT OR IGNORE INTO hak_akses_modul (role, modul, aksi) VALUES
  ('admin', 'semua', 'all'),
  ('kepala_sekolah', 'dashboard', 'view'),
  ('kepala_sekolah', 'jadwal', 'view'),
  ('kepala_sekolah', 'absensi', 'view'),
  ('kepala_sekolah', 'nilai', 'view'),
  ('kepala_sekolah', 'rapor', 'view'),
  ('kepala_sekolah', 'bk', 'view'),
  ('kepala_sekolah', 'laporan', 'view'),
  ('wakil_kurikulum', 'dashboard', 'view'),
  ('wakil_kurikulum', 'penjadwalan', 'all'),
  ('wakil_kurikulum', 'bobot_nilai', 'all'),
  ('wakil_kurikulum', 'kenaikan_kelas', 'all'),
  ('wakil_kurikulum', 'laporan', 'view'),
  ('guru_mapel_wali_kelas', 'dashboard', 'view'),
  ('guru_mapel_wali_kelas', 'absensi', 'create'),
  ('guru_mapel_wali_kelas', 'nilai', 'create'),
  ('guru_mapel_wali_kelas', 'rapor', 'create'),
  ('guru_mapel_wali_kelas', 'pengaduan', 'create'),
  ('guru_bk', 'dashboard', 'view'),
  ('guru_bk', 'pengaduan', 'all'),
  ('guru_bk', 'konseling', 'all'),
  ('guru_bk', 'laporan', 'view');

-- ============================================================
-- DISTRIBUSI MENGAJAR (contoh)
-- ============================================================

INSERT OR IGNORE INTO guru_mata_pelajaran (guru_id, mata_pelajaran_id, kelas_id, semester_id) VALUES
  (1, 1, 1, 3), (1, 1, 2, 3),
  (2, 2, 1, 3), (2, 2, 2, 3),
  (3, 3, 1, 3), (3, 3, 2, 3),
  (4, 4, 1, 3), (4, 4, 2, 3),
  (5, 5, 1, 3),
  (6, 6, 1, 3);

-- ============================================================
-- BOBOT NILAI DEFAULT
-- ============================================================

INSERT OR IGNORE INTO bobot_nilai (mata_pelajaran_id, tahun_ajaran_id, harian_persen, tugas_persen, uts_persen, uas_persen) VALUES
  (null, 2, 20, 20, 30, 30);
