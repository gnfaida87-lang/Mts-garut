-- ============================================================
-- Skema Database — MTs Garut
-- Target: Cloudflare D1 (SQLite)
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- 1. USER & HAK AKSES
-- ============================================================

CREATE TABLE users (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    username        TEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    role            TEXT NOT NULL CHECK (role IN (
                        'admin',
                        'kepala_sekolah',
                        'wakil_kurikulum',
                        'guru_mapel_wali_kelas',
                        'guru_bk',
                        'siswa',
                        'musyrifah'
                    )),
    guru_id         INTEGER REFERENCES guru(id),   -- null untuk admin/kepala sekolah jika tidak terhubung ke data guru
    siswa_id        INTEGER REFERENCES siswa(id),   -- link ke data siswa untuk role 'siswa'
    is_active       INTEGER NOT NULL DEFAULT 1,    -- 1 = aktif, 0 = nonaktif
    last_login_at   TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE hak_akses_modul (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    role        TEXT NOT NULL,
    modul       TEXT NOT NULL,      -- contoh: 'nilai', 'absensi', 'rapor'
    aksi        TEXT NOT NULL CHECK (aksi IN ('view','create','edit','delete','validate')),
    UNIQUE (role, modul, aksi)
);

CREATE TABLE log_aktivitas (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL REFERENCES users(id),
    aksi        TEXT NOT NULL,      -- contoh: 'login', 'input_nilai', 'validasi_absensi'
    modul       TEXT,
    detail      TEXT,
    ip_address  TEXT,
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 2. MASTER DATA (Admin)
-- ============================================================

CREATE TABLE tahun_ajaran (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nama            TEXT NOT NULL UNIQUE,   -- contoh: '2025/2026'
    tanggal_mulai   TEXT,
    tanggal_selesai TEXT,
    is_aktif        INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE semester (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    tahun_ajaran_id     INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    nama                TEXT NOT NULL CHECK (nama IN ('Ganjil','Genap')),
    is_aktif            INTEGER NOT NULL DEFAULT 0,
    nilai_published     INTEGER NOT NULL DEFAULT 0,
    UNIQUE (tahun_ajaran_id, nama)
);

CREATE TABLE jurusan (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    nama    TEXT NOT NULL,
    kode    TEXT UNIQUE
);

CREATE TABLE tingkat (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    nama    TEXT NOT NULL,               -- contoh: 'VII', 'X'
    jenjang TEXT NOT NULL CHECK (jenjang IN ('MTs','MA'))
);

CREATE TABLE ruangan (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nama        TEXT NOT NULL,
    kapasitas   INTEGER
);

CREATE TABLE mata_pelajaran (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    nama TEXT NOT NULL UNIQUE,
    kode TEXT UNIQUE
);

CREATE TABLE mapel_kelas (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id) ON DELETE CASCADE,
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    UNIQUE(mata_pelajaran_id, kelas_id)
);

CREATE TABLE guru (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nip             TEXT UNIQUE,
    nama            TEXT NOT NULL,
    jenis_kelamin   TEXT CHECK (jenis_kelamin IN ('L','P')),
    no_hp           TEXT,
    email           TEXT,
    jabatan         TEXT,
    status_aktif    INTEGER NOT NULL DEFAULT 1,
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE guru_mapel (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id           INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id) ON DELETE CASCADE,
    UNIQUE(guru_id, mata_pelajaran_id)
);

CREATE TABLE guru_kelas (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id  INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    kelas_id INTEGER NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    UNIQUE(guru_id, kelas_id)
);

-- Gabungan guru + mapel + kelas (spesifik: guru mengajar mapel X di kelas Y)
CREATE TABLE guru_mapel_kelas (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id           INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id) ON DELETE CASCADE,
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(guru_id, mata_pelajaran_id, kelas_id)
);

CREATE TABLE kelas (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nama            TEXT NOT NULL,          -- contoh: 'X IPA 1'
    tingkat_id      INTEGER NOT NULL REFERENCES tingkat(id),
    jurusan_id      INTEGER REFERENCES jurusan(id),
    wali_kelas_id   INTEGER REFERENCES guru(id),
    ruangan_id      INTEGER REFERENCES ruangan(id),
    tahun_ajaran_id INTEGER NOT NULL REFERENCES tahun_ajaran(id)
);

CREATE TABLE siswa (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nis             TEXT UNIQUE,
    nisn            TEXT UNIQUE,
    nama            TEXT NOT NULL,
    jenis_kelamin   TEXT CHECK (jenis_kelamin IN ('L','P')),
    tempat_lahir    TEXT,
    tanggal_lahir   TEXT,
    alamat          TEXT,
    no_hp_ortu      TEXT,
    nama_ayah       TEXT,
    nama_ibu        TEXT,
    pekerjaan_ayah  TEXT,
    pekerjaan_ibu   TEXT,
    whatsapp        TEXT,
    kelas_id        INTEGER REFERENCES kelas(id),
    tahun_ajaran_id INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    status          TEXT NOT NULL DEFAULT 'aktif'
                        CHECK (status IN ('aktif','lulus','pindah','keluar')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Penugasan mengajar guru per kelas/mapel (dipakai untuk beban mengajar & distribusi)
-- Kolom mata_pelajaran_id/kelas_id nullable: baris Kesiapan Mengajar disimpan
-- per guru+semester tanpa mapel/kelas (lihat migrasi 0021).
CREATE TABLE guru_mata_pelajaran (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id             INTEGER NOT NULL REFERENCES guru(id),
    mata_pelajaran_id   INTEGER REFERENCES mata_pelajaran(id),
    kelas_id            INTEGER REFERENCES kelas(id),
    semester_id         INTEGER NOT NULL REFERENCES semester(id),
    hari_aktif          TEXT DEFAULT '[]',          -- JSON array hari aktif (mis. ["Senin","Selasa"])
    jp_max_per_hari     INTEGER DEFAULT 8,          -- batas jam pelajaran per hari
    jp_max_per_minggu   INTEGER DEFAULT 24,         -- batas jam pelajaran per minggu
    UNIQUE (guru_id, mata_pelajaran_id, kelas_id, semester_id)
);

-- Satu baris Kesiapan Mengajar per guru+semester (mapel/kelas NULL)
CREATE UNIQUE INDEX IF NOT EXISTS ux_guru_mata_pelajaran_kesiapan
ON guru_mata_pelajaran (guru_id, semester_id)
WHERE mata_pelajaran_id IS NULL AND kelas_id IS NULL;

-- ============================================================
-- 3. PENJADWALAN (Wakil Kurikulum)
-- ============================================================

CREATE TABLE jadwal_pelajaran (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    mata_pelajaran_id   INTEGER REFERENCES mata_pelajaran(id),
    guru_id             INTEGER REFERENCES guru(id),
    ruangan_id          INTEGER REFERENCES ruangan(id),
    nama_kegiatan       TEXT,
    is_istirahat        INTEGER NOT NULL DEFAULT 0,
    hari                TEXT NOT NULL CHECK (hari IN (
                            'Sabtu','Minggu','Senin','Selasa','Rabu','Kamis'
                        )),
    jam_mulai           TEXT NOT NULL,   -- format 'HH:MM'
    jam_selesai         TEXT NOT NULL,
    semester_id         INTEGER NOT NULL REFERENCES semester(id),
    status_validasi     TEXT NOT NULL DEFAULT 'draft'
                            CHECK (status_validasi IN ('draft','tervalidasi'))
);

-- Jam pelajaran (JP1..JP12) — waktu dapat diatur manual oleh Wakil Kurikulum.
-- tipe: 'pelajaran' = jam mengajar, 'istirahat' = slot kosong untuk kegiatan istirahat.
CREATE TABLE jp_slot (
    kode     TEXT PRIMARY KEY,          -- 'JP1'..'JP12'
    mulai    TEXT NOT NULL,             -- format 'HH:MM'
    selesai  TEXT NOT NULL,             -- format 'HH:MM'
    urutan   INTEGER NOT NULL,
    tipe     TEXT NOT NULL DEFAULT 'pelajaran'
);

INSERT OR IGNORE INTO jp_slot (kode, mulai, selesai, urutan, tipe) VALUES
    ('JP1',  '07:00', '07:40', 1,  'pelajaran'),
    ('JP2',  '07:40', '08:20', 2,  'pelajaran'),
    ('JP3',  '08:20', '09:00', 3,  'pelajaran'),
    ('JP4',  '09:00', '09:20', 4,  'istirahat'),
    ('JP5',  '09:20', '09:40', 5,  'pelajaran'),
    ('JP6',  '09:40', '10:00', 6,  'istirahat'),
    ('JP7',  '10:00', '10:40', 7,  'pelajaran'),
    ('JP8',  '10:40', '11:20', 8,  'pelajaran'),
    ('JP9',  '11:20', '12:00', 9,  'pelajaran'),
    ('JP10', '12:00', '12:40', 10, 'istirahat'),
    ('JP11', '12:40', '13:20', 11, 'pelajaran'),
    ('JP12', '13:20', '14:00', 12, 'pelajaran');

-- ============================================================
-- 4. ABSENSI
-- ============================================================

CREATE TABLE absensi_guru (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id     INTEGER NOT NULL REFERENCES guru(id),
    tanggal     TEXT NOT NULL,
    jam_masuk   TEXT,
    jam_keluar  TEXT,
    status      TEXT NOT NULL CHECK (status IN ('hadir','izin','sakit','alpa')),
    keterangan  TEXT,
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE (guru_id, tanggal)
);

CREATE TABLE absensi_siswa (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id            INTEGER NOT NULL REFERENCES siswa(id),
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    mata_pelajaran_id   INTEGER REFERENCES mata_pelajaran(id),  -- null = absensi harian umum
    tanggal             TEXT NOT NULL,
    jam                 TEXT,                       -- jam pelajaran (mis. '07:00')
    status              TEXT NOT NULL CHECK (status IN ('hadir','izin','sakit','alpa')),
    keterangan          TEXT,
    diinput_oleh        INTEGER NOT NULL REFERENCES guru(id),
    created_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 5. NILAI & RAPOR
-- ============================================================

CREATE TABLE bobot_nilai (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    mata_pelajaran_id   INTEGER REFERENCES mata_pelajaran(id),  -- null = bobot default sekolah
    tahun_ajaran_id     INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    harian_persen       REAL NOT NULL DEFAULT 20,
    tugas_persen        REAL NOT NULL DEFAULT 20,
    uts_persen          REAL NOT NULL DEFAULT 30,
    uas_persen          REAL NOT NULL DEFAULT 30
);

CREATE TABLE nilai (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id            INTEGER NOT NULL REFERENCES siswa(id),
    mata_pelajaran_id   INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    semester_id         INTEGER NOT NULL REFERENCES semester(id),
    jenis               TEXT NOT NULL CHECK (jenis IN (
                            'harian','tugas','uts','uas','akhir',
                            'pts1','pas','pts2','pat'
                        )),
    nilai               REAL NOT NULL,
    keterangan          TEXT,
    diinput_oleh        INTEGER NOT NULL REFERENCES guru(id),
    status_validasi     TEXT NOT NULL DEFAULT 'draft'
                            CHECK (status_validasi IN ('draft','tervalidasi')),
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(siswa_id, mata_pelajaran_id, semester_id, jenis, diinput_oleh)
);

CREATE TABLE nilai_rapor (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id            INTEGER NOT NULL REFERENCES siswa(id),
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    semester_id         INTEGER NOT NULL REFERENCES semester(id),
    mata_pelajaran_id   INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    nilai_akhir         REAL,
    predikat            TEXT,
    catatan_wali_kelas  TEXT,
    status_kirim        TEXT NOT NULL DEFAULT 'draft'
                            CHECK (status_kirim IN ('draft','terkirim','divalidasi')),
    wali_kelas_id       INTEGER REFERENCES guru(id),
    UNIQUE (siswa_id, semester_id, mata_pelajaran_id)
);

CREATE TABLE rapor_arsip (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id        INTEGER NOT NULL REFERENCES siswa(id),
    semester_id     INTEGER NOT NULL REFERENCES semester(id),
    file_url        TEXT,           -- lokasi file PDF rapor (mis. R2/Cloudflare Storage)
    dicetak_pada    TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 6. MATERI (Guru Mapel)
-- ============================================================

CREATE TABLE materi (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id             INTEGER NOT NULL REFERENCES guru(id),
    mata_pelajaran_id   INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    judul               TEXT NOT NULL,
    deskripsi           TEXT,
    link_url            TEXT NOT NULL,       -- link Google Drive
    link_youtube         TEXT,                -- link YouTube (opsional)
    pertemuan           TEXT,                -- nomor/label pertemuan (mis. '1', '2', 'Pertemuan 1')
    is_aktif            INTEGER NOT NULL DEFAULT 1,  -- 1 = aktif, 0 = tidak aktif
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 6b. PENGADUAN (Guru Mapel/Wali Kelas -> dilihat oleh Guru BK)
-- ============================================================

CREATE TABLE pengaduan (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id        INTEGER NOT NULL REFERENCES siswa(id),
    kategori        TEXT NOT NULL CHECK (kategori IN ('perilaku','kasus')),
    deskripsi       TEXT NOT NULL,
    bukti_url       TEXT,           -- link foto/video bukti
    dilaporkan_oleh INTEGER NOT NULL REFERENCES guru(id),
    status          TEXT NOT NULL DEFAULT 'baru'
                        CHECK (status IN ('baru','diproses','selesai')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 7. BK — KONSELING & BAKAT MINAT (Guru BK)
-- ============================================================

CREATE TABLE jadwal_konseling (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id    INTEGER REFERENCES siswa(id),   -- null jika konseling kelompok
    guru_bk_id  INTEGER NOT NULL REFERENCES guru(id),
    tanggal     TEXT NOT NULL,
    jam         TEXT,
    hari        TEXT,                            -- hari dalam seminggu (opsional)
    jenis       TEXT NOT NULL CHECK (jenis IN ('individu','kelompok','online')),
    status      TEXT NOT NULL DEFAULT 'terjadwal'
                    CHECK (status IN ('terjadwal','selesai','batal'))
);

CREATE TABLE konseling (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    jadwal_id       INTEGER REFERENCES jadwal_konseling(id),
    siswa_id        INTEGER NOT NULL REFERENCES siswa(id),
    guru_bk_id      INTEGER NOT NULL REFERENCES guru(id),
    tanggal         TEXT NOT NULL,
    catatan         TEXT,
    tindak_lanjut   TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE bakat_minat (
    id                      INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id                INTEGER NOT NULL REFERENCES siswa(id),
    jenis                   TEXT NOT NULL CHECK (jenis IN ('bakat','minat')),
    deskripsi               TEXT NOT NULL,
    catatan_pengembangan    TEXT,
    guru_bk_id              INTEGER NOT NULL REFERENCES guru(id),
    created_at              TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 9. PENGATURAN TAMPILAN (Admin)
-- ============================================================

CREATE TABLE pengaturan (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    key         TEXT NOT NULL UNIQUE,
    value       TEXT NOT NULL DEFAULT '',
    updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT OR IGNORE INTO pengaturan (key, value) VALUES
    ('hero_title', 'MA PERSIS GARUT'),
    ('hero_subtitle', 'Absensi, Jadwal, Nilai, dan Lainnya'),
    ('logo_url', ''),
    ('background_url', '');

-- ============================================================
-- 8. KENAIKAN KELAS & ALUMNI (Wakil Kurikulum)
-- ============================================================

CREATE TABLE kenaikan_kelas (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id            INTEGER NOT NULL REFERENCES siswa(id),
    dari_kelas_id       INTEGER NOT NULL REFERENCES kelas(id),
    ke_kelas_id         INTEGER REFERENCES kelas(id),   -- null jika tidak naik/lulus
    tahun_ajaran_id     INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    status              TEXT NOT NULL CHECK (status IN ('naik','tidak_naik','lulus')),
    no_surat_keputusan  TEXT,
    tanggal_keputusan   TEXT,
    created_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE alumni (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id        INTEGER NOT NULL REFERENCES siswa(id),
    tahun_lulus     TEXT NOT NULL,
    kontak          TEXT,
    catatan         TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Konfigurasi batas minimum kenaikan kelas per tahun ajaran
CREATE TABLE pengaturan_kenaikan_kelas (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    tahun_ajaran_id     INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    min_absensi_persen  REAL NOT NULL DEFAULT 75,
    min_nilai_akhir     REAL NOT NULL DEFAULT 60,
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE (tahun_ajaran_id)
);

-- ============================================================
-- INDEX PENDUKUNG PERFORMA
-- ============================================================

CREATE INDEX idx_siswa_kelas          ON siswa(kelas_id);
CREATE INDEX idx_nilai_siswa          ON nilai(siswa_id, semester_id);
CREATE INDEX idx_nilai_diinput        ON nilai(diinput_oleh);
CREATE INDEX idx_absensi_siswa_tgl    ON absensi_siswa(siswa_id, tanggal);
CREATE INDEX idx_absensi_kelas_tgl    ON absensi_siswa(kelas_id, tanggal);
CREATE INDEX idx_absensi_guru_tgl     ON absensi_guru(guru_id, tanggal);
CREATE INDEX idx_jadwal_kelas         ON jadwal_pelajaran(kelas_id, semester_id);
CREATE INDEX idx_jadwal_guru          ON jadwal_pelajaran(guru_id, semester_id);
CREATE INDEX idx_jadwal_hari          ON jadwal_pelajaran(hari, guru_id);
CREATE INDEX idx_materi_guru          ON materi(guru_id);
CREATE INDEX idx_materi_kelas         ON materi(kelas_id, is_aktif);
CREATE INDEX idx_pengaduan_siswa      ON pengaduan(siswa_id);
CREATE INDEX idx_pengaduan_pelapor    ON pengaduan(dilaporkan_oleh);
CREATE INDEX idx_pengaduan_status     ON pengaduan(status);
CREATE INDEX idx_konseling_siswa      ON konseling(siswa_id);
CREATE INDEX idx_gmk_guru             ON guru_mapel_kelas(guru_id);
CREATE INDEX idx_gmk_mapel            ON guru_mapel_kelas(mata_pelajaran_id);
CREATE INDEX idx_gmk_kelas            ON guru_mapel_kelas(kelas_id);
CREATE INDEX idx_gmk_guru_mapel       ON guru_mapel_kelas(guru_id, mata_pelajaran_id);
CREATE INDEX idx_gmk_guru_kelas       ON guru_mapel_kelas(guru_id, kelas_id);

-- ============================================================
-- 10. MODUL DAUROH (Musyrifah & Admin)
-- ============================================================

CREATE TABLE dauroh_program (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nama_program    TEXT NOT NULL,
    jenis_program   TEXT NOT NULL CHECK (jenis_program IN ('khusus', 'kelas')),
    jenis_dauroh    TEXT NOT NULL CHECK (jenis_dauroh IN ('murojaah', 'tahfidz')),
    skema_penilaian TEXT DEFAULT 'murojaah_tahfidz',
    keterangan      TEXT,
    tahun_ajaran_id INTEGER REFERENCES tahun_ajaran(id),
    is_aktif        INTEGER NOT NULL DEFAULT 1,
    -- Konfigurasi Skema Penilaian
    max_bidang1     INTEGER DEFAULT 40,
    max_bidang2     INTEGER DEFAULT 30,
    max_bidang3     INTEGER DEFAULT 30,
    label_bidang1   TEXT DEFAULT 'Kelancaran Hafalan',
    label_bidang2   TEXT DEFAULT 'Tajwid',
    label_bidang3   TEXT DEFAULT 'Fashohah dan Adab',
    konfigurasi_nilai TEXT,  -- JSON untuk custom schema
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE dauroh_musyrifah (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    nipmus              TEXT UNIQUE NOT NULL,
    nama                TEXT NOT NULL,
    jenis_kelamin       TEXT CHECK (jenis_kelamin IN ('L', 'P')),
    status_pendidikan   TEXT CHECK (status_pendidikan IN ('selesai', 'mahasiswa')),
    gelar               TEXT,
    username            TEXT UNIQUE NOT NULL,
    password_hash       TEXT NOT NULL,
    is_aktif            INTEGER NOT NULL DEFAULT 1,
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE dauroh_jadwal (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    program_id      INTEGER NOT NULL REFERENCES dauroh_program(id),
    musyrifah_1_id  INTEGER NOT NULL REFERENCES dauroh_musyrifah(id),
    musyrifah_2_id  INTEGER REFERENCES dauroh_musyrifah(id),
    jenjang         TEXT,
    hari            TEXT NOT NULL CHECK (hari IN ('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu')),
    jam_mulai       TEXT NOT NULL,
    jam_selesai     TEXT NOT NULL,
    is_aktif        INTEGER NOT NULL DEFAULT 1,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE dauroh_jadwal_kelas (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    jadwal_id   INTEGER NOT NULL REFERENCES dauroh_jadwal(id) ON DELETE CASCADE,
    kelas_id    INTEGER NOT NULL REFERENCES kelas(id),
    UNIQUE(jadwal_id, kelas_id)
);

CREATE TABLE dauroh_program_santri (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    program_id  INTEGER NOT NULL REFERENCES dauroh_program(id) ON DELETE CASCADE,
    santri_id   INTEGER NOT NULL REFERENCES siswa(id),
    UNIQUE(program_id, santri_id)
);

CREATE TABLE dauroh_absensi_musyrifah (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    musyrifah_id    INTEGER NOT NULL REFERENCES dauroh_musyrifah(id),
    jadwal_id       INTEGER NOT NULL REFERENCES dauroh_jadwal(id),
    tanggal         TEXT NOT NULL,
    waktu_scan      TEXT NOT NULL,
    waktu_masuk     TEXT,
    waktu_keluar    TEXT,
    status          TEXT NOT NULL DEFAULT 'hadir' CHECK (status IN ('hadir', 'izin', 'sakit', 'alpha')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(musyrifah_id, jadwal_id, tanggal)
);

CREATE TABLE dauroh_absensi_santri (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    jadwal_id   INTEGER NOT NULL REFERENCES dauroh_jadwal(id),
    santri_id   INTEGER NOT NULL REFERENCES siswa(id),
    tanggal     TEXT NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('hadir', 'izin', 'sakit', 'alpha')),
    keterangan  TEXT,
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(jadwal_id, santri_id, tanggal)
);

-- Tabel Referensi Surat Al-Quran
CREATE TABLE dauroh_surat (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nomor           INTEGER NOT NULL UNIQUE,
    nama            TEXT NOT NULL,
    nama_arab       TEXT,
    jumlah_ayat     INTEGER NOT NULL,
    juz             INTEGER NOT NULL,
    type            TEXT NOT NULL CHECK(type IN ('makkiyah', 'madaniyah')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Tabel Nilai Dauroh (Enhanced)
CREATE TABLE dauroh_nilai (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Foreign Keys
    program_id      INTEGER NOT NULL REFERENCES dauroh_program(id) ON DELETE CASCADE,
    santri_id       INTEGER NOT NULL REFERENCES siswa(id) ON DELETE CASCADE,
    jadwal_id       INTEGER REFERENCES dauroh_jadwal(id),
    
    -- Metadata Hafalan
    surat_nomor     INTEGER REFERENCES dauroh_surat(nomor),
    dari_ayat       INTEGER,
    sampai_ayat     INTEGER,
    status_hafalan  TEXT NOT NULL DEFAULT 'melanjutkan' 
                        CHECK(status_hafalan IN ('mengulang', 'melanjutkan', 'selesai')),
    
    -- Bidang 1: Kelancaran Hafalan (Max 40)
    kelancaran          INTEGER CHECK(kelancaran BETWEEN 1 AND 5),
    ketepatan_ayat      INTEGER CHECK(ketepatan_ayat BETWEEN 1 AND 5),
    murojaah_sambung    INTEGER CHECK(murojaah_sambung BETWEEN 1 AND 5),
    konsistensi_hafalan INTEGER CHECK(konsistensi_hafalan BETWEEN 1 AND 5),
    catatan_bidang1     TEXT,
    
    -- Bidang 2: Tajwid (Max 30)
    makhorijul_huruf    INTEGER CHECK(makhorijul_huruf BETWEEN 1 AND 5),
    sifatul_huruf       INTEGER CHECK(sifatul_huruf BETWEEN 1 AND 5),
    ahkamul_huruf       INTEGER CHECK(ahkamul_huruf BETWEEN 1 AND 5),
    ahkamul_madd        INTEGER CHECK(ahkamul_madd BETWEEN 1 AND 5),
    catatan_bidang2     TEXT,
    
    -- Bidang 3: Fashohah dan Adab (Max 30)
    ahkamul_waqfi       INTEGER CHECK(ahkamul_waqfi BETWEEN 1 AND 5),
    adabut_tilawah      INTEGER CHECK(adabut_tilawah BETWEEN 1 AND 5),
    kerapihan_bacaan    INTEGER CHECK(kerapihan_bacaan BETWEEN 1 AND 5),
    ketepatan_tempo     INTEGER CHECK(ketepatan_tempo BETWEEN 1 AND 5),
    catatan_bidang3     TEXT,
    
    -- Catatan
    catatan_umum        TEXT,
    rencana_tindak_lanjut TEXT,
    
    -- Computed Columns (SQLite 3.31.0+)
    nilai_bidang1 INTEGER GENERATED ALWAYS AS (
        44 - COALESCE(kelancaran, 0) - COALESCE(ketepatan_ayat, 0) - 
        COALESCE(murojaah_sambung, 0) - COALESCE(konsistensi_hafalan, 0)
    ) STORED,
    
    nilai_bidang2 INTEGER GENERATED ALWAYS AS (
        34 - COALESCE(makhorijul_huruf, 0) - COALESCE(sifatul_huruf, 0) - 
        COALESCE(ahkamul_huruf, 0) - COALESCE(ahkamul_madd, 0)
    ) STORED,
    
    nilai_bidang3 INTEGER GENERATED ALWAYS AS (
        34 - COALESCE(ahkamul_waqfi, 0) - COALESCE(adabut_tilawah, 0) - 
        COALESCE(kerapihan_bacaan, 0) - COALESCE(ketepatan_tempo, 0)
    ) STORED,
    
    total_nilai INTEGER GENERATED ALWAYS AS (
        (44 - COALESCE(kelancaran, 0) - COALESCE(ketepatan_ayat, 0) - 
         COALESCE(murojaah_sambung, 0) - COALESCE(konsistensi_hafalan, 0)) +
        (34 - COALESCE(makhorijul_huruf, 0) - COALESCE(sifatul_huruf, 0) - 
         COALESCE(ahkamul_huruf, 0) - COALESCE(ahkamul_madd, 0)) +
        (34 - COALESCE(ahkamul_waqfi, 0) - COALESCE(adabut_tilawah, 0) - 
         COALESCE(kerapihan_bacaan, 0) - COALESCE(ketepatan_tempo, 0))
    ) STORED,
    
    -- Audit
    diinput_oleh    INTEGER REFERENCES dauroh_musyrifah(id),
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    
    UNIQUE(program_id, santri_id, surat_nomor, dari_ayat, sampai_ayat)
);

-- Dauroh indexes
CREATE INDEX idx_dauroh_program_ta ON dauroh_program(tahun_ajaran_id);
CREATE INDEX idx_dauroh_jadwal_program ON dauroh_jadwal(program_id);
CREATE INDEX idx_dauroh_jadwal_musyrifah1 ON dauroh_jadwal(musyrifah_1_id);
CREATE INDEX idx_dauroh_jadwal_musyrifah2 ON dauroh_jadwal(musyrifah_2_id);
CREATE INDEX idx_dauroh_jadwal_kelas_jadwal ON dauroh_jadwal_kelas(jadwal_id);
CREATE INDEX idx_dauroh_jadwal_kelas_kelas ON dauroh_jadwal_kelas(kelas_id);
CREATE INDEX idx_dauroh_program_santri_program ON dauroh_program_santri(program_id);
CREATE INDEX idx_dauroh_program_santri_santri ON dauroh_program_santri(santri_id);
CREATE INDEX idx_dauroh_absensi_musyrifah_musyrifah ON dauroh_absensi_musyrifah(musyrifah_id);
CREATE INDEX idx_dauroh_absensi_musyrifah_jadwal ON dauroh_absensi_musyrifah(jadwal_id);
CREATE INDEX idx_dauroh_absensi_musyrifah_tanggal ON dauroh_absensi_musyrifah(tanggal);
CREATE INDEX idx_dauroh_absensi_santri_jadwal ON dauroh_absensi_santri(jadwal_id);
CREATE INDEX idx_dauroh_absensi_santri_santri ON dauroh_absensi_santri(santri_id);
CREATE INDEX idx_dauroh_absensi_santri_tanggal ON dauroh_absensi_santri(tanggal);
CREATE INDEX idx_dauroh_nilai_program ON dauroh_nilai(program_id);
CREATE INDEX idx_dauroh_nilai_santri ON dauroh_nilai(santri_id);
CREATE INDEX idx_dauroh_nilai_status ON dauroh_nilai(status_hafalan);
CREATE INDEX idx_dauroh_nilai_surat ON dauroh_nilai(surat_nomor);
CREATE INDEX idx_dauroh_nilai_jadwal ON dauroh_nilai(jadwal_id);
CREATE INDEX idx_surat_juz ON dauroh_surat(juz);
CREATE INDEX idx_surat_type ON dauroh_surat(type);

-- ============================================================
-- 11. API KEYS & SISTEM 2 INTEGRATION
-- ============================================================

CREATE TABLE api_keys (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nama_pihak      TEXT NOT NULL,                    -- nama pihak ketiga (mis. "Bank BRI", "Toko Maju")
    api_key_hash    TEXT NOT NULL,                    -- bcrypt hash dari api_key
    permissions     TEXT NOT NULL DEFAULT 'read',     -- 'read', 'write', 'readwrite'
    rate_limit      INTEGER NOT NULL DEFAULT 5000,    -- request per hari
    is_aktif        INTEGER NOT NULL DEFAULT 1,       -- 1 = aktif, 0 = nonaktif
    last_used_at    TEXT,                             -- timestamp terakhir digunakan
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_api_keys_is_aktif ON api_keys(is_aktif);
CREATE INDEX idx_api_keys_nama_pihak ON api_keys(nama_pihak);

-- Rate limit tracking per API Key per hari
CREATE TABLE api_key_rate_limits (
    api_key_id      INTEGER NOT NULL REFERENCES api_keys(id) ON DELETE CASCADE,
    date            TEXT NOT NULL,                    -- YYYY-MM-DD
    count           INTEGER NOT NULL DEFAULT 0,
    window_start    INTEGER NOT NULL,                 -- epoch ms
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (api_key_id, date)
);

-- Tabel Jenis Pembayaran (Master data, dikelola Admin)
CREATE TABLE jenis_pembayaran (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nama        TEXT NOT NULL UNIQUE,         -- contoh: "SPP Bulanan", "Dauroh", "Seragam"
    kode        TEXT UNIQUE,                  -- kode singkat: "SPP", "DAUROH", "SERAGAM"
    deskripsi   TEXT,
    is_aktif    INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Tabel Pembayaran (dipush oleh Sistem 2 via API Key)
CREATE TABLE pembayaran (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    santri_id           INTEGER NOT NULL REFERENCES siswa(id) ON DELETE CASCADE,
    jenis_pembayaran_id INTEGER NOT NULL REFERENCES jenis_pembayaran(id),
    jumlah              REAL NOT NULL,                -- nominal pembayaran
    status              TEXT NOT NULL DEFAULT '***'   -- '*' = Lunas, '**' = Proses, '***' = Belum Bayar
                          CHECK (status IN ('*', '**', '***')),
    tanggal_bayar       TEXT,                         -- tanggal pembayaran (jika sudah bayar)
    bukti_url           TEXT,                         -- URL bukti transfer (opsional)
    catatan             TEXT,
    api_key_id          INTEGER REFERENCES api_keys(id), -- tracking pihak yang input
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_pembayaran_santri ON pembayaran(santri_id);
CREATE INDEX idx_pembayaran_status ON pembayaran(status);
CREATE INDEX idx_pembayaran_jenis ON pembayaran(jenis_pembayaran_id);
CREATE INDEX idx_pembayaran_tanggal ON pembayaran(tanggal_bayar);
CREATE INDEX idx_pembayaran_api_key ON pembayaran(api_key_id);

-- Tabel Notifikasi (dipush oleh Sistem 2 via API Key)
CREATE TABLE notifikasi (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    santri_id       INTEGER NOT NULL REFERENCES siswa(id) ON DELETE CASCADE,
    judul           TEXT NOT NULL,
    pesan           TEXT NOT NULL,
    tipe            TEXT NOT NULL DEFAULT 'info'  -- 'info', 'warning', 'success', 'error'
                      CHECK (tipe IN ('info', 'warning', 'success', 'error')),
    is_read         INTEGER NOT NULL DEFAULT 0,   -- 0 = belum dibaca, 1 = sudah dibaca
    api_key_id      INTEGER REFERENCES api_keys(id),
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_notifikasi_santri ON notifikasi(santri_id);
CREATE INDEX idx_notifikasi_is_read ON notifikasi(is_read);
CREATE INDEX idx_notifikasi_created ON notifikasi(created_at);
