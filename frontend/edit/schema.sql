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
                        'siswa'
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
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    tahun_ajaran_id INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    nama            TEXT NOT NULL CHECK (nama IN ('Ganjil','Genap')),
    is_aktif        INTEGER NOT NULL DEFAULT 0,
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
    nama TEXT NOT NULL,
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
    kelas_id        INTEGER REFERENCES kelas(id),
    tahun_ajaran_id INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    status          TEXT NOT NULL DEFAULT 'aktif'
                        CHECK (status IN ('aktif','lulus','pindah','keluar')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Penugasan mengajar guru per kelas/mapel (dipakai untuk beban mengajar & distribusi)
CREATE TABLE guru_mata_pelajaran (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id             INTEGER NOT NULL REFERENCES guru(id),
    mata_pelajaran_id   INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    semester_id         INTEGER NOT NULL REFERENCES semester(id),
    UNIQUE (guru_id, mata_pelajaran_id, kelas_id, semester_id)
);

-- ============================================================
-- 3. PENJADWALAN (Wakil Kurikulum)
-- ============================================================

CREATE TABLE jadwal_pelajaran (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    mata_pelajaran_id   INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    guru_id             INTEGER NOT NULL REFERENCES guru(id),
    ruangan_id          INTEGER REFERENCES ruangan(id),
    hari                TEXT NOT NULL CHECK (hari IN (
                            'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'
                        )),
    jam_mulai           TEXT NOT NULL,   -- format 'HH:MM'
    jam_selesai         TEXT NOT NULL,
    semester_id         INTEGER NOT NULL REFERENCES semester(id),
    status_validasi     TEXT NOT NULL DEFAULT 'draft'
                            CHECK (status_validasi IN ('draft','tervalidasi'))
);

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
                            'harian','tugas','uts','uas','akhir'
                        )),
    nilai               REAL NOT NULL,
    keterangan          TEXT,
    diinput_oleh        INTEGER NOT NULL REFERENCES guru(id),
    status_validasi     TEXT NOT NULL DEFAULT 'draft'
                            CHECK (status_validasi IN ('draft','tervalidasi')),
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
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
-- 6. PENGADUAN (Guru Mapel/Wali Kelas -> dilihat oleh Guru BK)
-- ============================================================

CREATE TABLE pengaduan (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id        INTEGER NOT NULL REFERENCES siswa(id),
    kategori        TEXT NOT NULL CHECK (kategori IN ('perilaku','kasus')),
    deskripsi       TEXT NOT NULL,
    bukti_url       TEXT,           -- link foto/video bukti
    dilaporkan_oleh INTEGER NOT NULL REFERENCES guru(id),
    status          TEXT NOT NULL DEFAULT 'baru'
                        CHECK (status IN ('baru','ditindaklanjuti','selesai')),
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
    jenis       TEXT NOT NULL CHECK (jenis IN ('individu','kelompok')),
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
    ('hero_title', 'Sistem Informasi Madrasah'),
    ('hero_subtitle', 'Kelola data akademik, absensi, nilai, rapor, dan bimbingan konseling dalam satu platform.'),
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
CREATE INDEX idx_absensi_siswa_tgl    ON absensi_siswa(siswa_id, tanggal);
CREATE INDEX idx_absensi_guru_tgl     ON absensi_guru(guru_id, tanggal);
CREATE INDEX idx_jadwal_kelas         ON jadwal_pelajaran(kelas_id, semester_id);
CREATE INDEX idx_pengaduan_siswa      ON pengaduan(siswa_id);
CREATE INDEX idx_konseling_siswa      ON konseling(siswa_id);
