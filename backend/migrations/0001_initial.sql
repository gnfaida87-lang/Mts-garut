-- Migration 0001: Initial Schema
-- Created: 2026-07-27
-- Target: Cloudflare D1 (SQLite)

PRAGMA foreign_keys = ON;

-- ============================================================
-- 1. USER & HAK AKSES
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    username        TEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    role            TEXT NOT NULL CHECK (role IN ('admin','kepala_sekolah','wakil_kurikulum','guru_mapel_wali_kelas','guru_bk')),
    guru_id         INTEGER REFERENCES guru(id),
    is_active       INTEGER NOT NULL DEFAULT 1,
    last_login_at   TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS hak_akses_modul (
    id    INTEGER PRIMARY KEY AUTOINCREMENT,
    role  TEXT NOT NULL,
    modul TEXT NOT NULL,
    aksi  TEXT NOT NULL CHECK (aksi IN ('view','create','edit','delete','validate')),
    UNIQUE(role, modul, aksi)
);

CREATE TABLE IF NOT EXISTS log_aktivitas (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER REFERENCES users(id),
    aksi       TEXT NOT NULL,
    modul      TEXT NOT NULL,
    detail     TEXT,
    ip_address TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_log_aktivitas_user ON log_aktivitas(user_id);
CREATE INDEX IF NOT EXISTS idx_log_aktivitas_created ON log_aktivitas(created_at);

-- ============================================================
-- 2. MASTER DATA
-- ============================================================

CREATE TABLE IF NOT EXISTS tahun_ajaran (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    nama             TEXT NOT NULL UNIQUE,
    tanggal_mulai    TEXT,
    tanggal_selesai  TEXT,
    is_aktif         INTEGER NOT NULL DEFAULT 0,
    created_at       TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS semester (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    tahun_ajaran_id INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    nama            TEXT NOT NULL,
    is_aktif        INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(tahun_ajaran_id, nama)
);

CREATE TABLE IF NOT EXISTS jurusan (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    nama       TEXT NOT NULL UNIQUE,
    kode       TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS tingkat (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    nama       TEXT NOT NULL UNIQUE,
    jenjang    TEXT NOT NULL CHECK (jenjang IN ('MTs','MA','MA/MTs')),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ruangan (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    nama       TEXT NOT NULL UNIQUE,
    kapasitas  INTEGER DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS mata_pelajaran (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    nama       TEXT NOT NULL,
    kode       TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS mapel_kelas (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id) ON DELETE CASCADE,
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    UNIQUE(mata_pelajaran_id, kelas_id)
);

CREATE TABLE IF NOT EXISTS guru (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    nip          TEXT UNIQUE,
    nama         TEXT NOT NULL,
    jenis_kelamin TEXT CHECK (jenis_kelamin IN ('L','P')),
    no_hp        TEXT,
    email        TEXT,
    jabatan      TEXT,
    status_aktif INTEGER NOT NULL DEFAULT 1,
    created_at   TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS guru_mapel (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id           INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id) ON DELETE CASCADE,
    UNIQUE(guru_id, mata_pelajaran_id)
);

CREATE TABLE IF NOT EXISTS guru_kelas (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id  INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    kelas_id INTEGER NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    UNIQUE(guru_id, kelas_id)
);

CREATE TABLE IF NOT EXISTS kelas (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    nama           TEXT NOT NULL,
    tingkat_id     INTEGER REFERENCES tingkat(id),
    jurusan_id     INTEGER REFERENCES jurusan(id),
    wali_kelas_id  INTEGER REFERENCES guru(id),
    ruangan_id     INTEGER REFERENCES ruangan(id),
    tahun_ajaran_id INTEGER REFERENCES tahun_ajaran(id),
    created_at     TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at     TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(nama, tahun_ajaran_id)
);

CREATE TABLE IF NOT EXISTS siswa (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nis             TEXT NOT NULL UNIQUE,
    nisn            TEXT,
    nama            TEXT NOT NULL,
    jenis_kelamin   TEXT CHECK (jenis_kelamin IN ('L','P')),
    tempat_lahir    TEXT,
    tanggal_lahir   TEXT,
    alamat          TEXT,
    no_hp_ortu      TEXT,
    kelas_id        INTEGER REFERENCES kelas(id),
    tahun_ajaran_id INTEGER REFERENCES tahun_ajaran(id),
    status          TEXT NOT NULL DEFAULT 'aktif' CHECK (status IN ('aktif','lulus','keluar')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_siswa_kelas ON siswa(kelas_id);
CREATE INDEX IF NOT EXISTS idx_siswa_status ON siswa(status);

-- ============================================================
-- 3. PENJADWALAN
-- ============================================================

CREATE TABLE IF NOT EXISTS guru_mata_pelajaran (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id           INTEGER NOT NULL REFERENCES guru(id),
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id),
    semester_id       INTEGER NOT NULL REFERENCES semester(id),
    UNIQUE(guru_id, mata_pelajaran_id, kelas_id, semester_id)
);

CREATE TABLE IF NOT EXISTS jadwal_pelajaran (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id),
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    guru_id           INTEGER NOT NULL REFERENCES guru(id),
    ruangan_id        INTEGER REFERENCES ruangan(id),
    hari              TEXT NOT NULL CHECK (hari IN ('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu')),
    jam_mulai         TEXT NOT NULL,
    jam_selesai       TEXT NOT NULL,
    semester_id       INTEGER NOT NULL REFERENCES semester(id),
    status_validasi   TEXT NOT NULL DEFAULT 'draft' CHECK (status_validasi IN ('draft','tervalidasi')),
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_jadwal_kelas ON jadwal_pelajaran(kelas_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_guru ON jadwal_pelajaran(guru_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_semester ON jadwal_pelajaran(semester_id);

-- ============================================================
-- 4. ABSENSI
-- ============================================================

CREATE TABLE IF NOT EXISTS absensi_guru (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id   INTEGER NOT NULL REFERENCES guru(id),
    tanggal   TEXT NOT NULL,
    status    TEXT NOT NULL CHECK (status IN ('hadir','sakit','izin','alpa')),
    keterangan TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(guru_id, tanggal)
);

CREATE TABLE IF NOT EXISTS absensi_siswa (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id          INTEGER NOT NULL REFERENCES siswa(id),
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id),
    mata_pelajaran_id INTEGER REFERENCES mata_pelajaran(id),
    tanggal           TEXT NOT NULL,
    status            TEXT NOT NULL CHECK (status IN ('hadir','sakit','izin','alpa')),
    keterangan        TEXT,
    diinput_oleh      INTEGER REFERENCES guru(id),
    created_at        TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_absensi_siswa_tanggal ON absensi_siswa(tanggal);
CREATE INDEX IF NOT EXISTS idx_absensi_siswa_kelas ON absensi_siswa(kelas_id);

-- ============================================================
-- 5. NILAI & RAPOR
-- ============================================================

CREATE TABLE IF NOT EXISTS bobot_nilai (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    mata_pelajaran_id INTEGER REFERENCES mata_pelajaran(id),
    tahun_ajaran_id   INTEGER REFERENCES tahun_ajaran(id),
    harian_persen     INTEGER NOT NULL DEFAULT 20,
    tugas_persen      INTEGER NOT NULL DEFAULT 20,
    uts_persen        INTEGER NOT NULL DEFAULT 30,
    uas_persen        INTEGER NOT NULL DEFAULT 30,
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS nilai (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id          INTEGER NOT NULL REFERENCES siswa(id),
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id),
    semester_id       INTEGER NOT NULL REFERENCES semester(id),
    jenis             TEXT NOT NULL CHECK (jenis IN ('harian','tugas','uts','uas','akhir')),
    nilai             REAL NOT NULL,
    keterangan        TEXT,
    status_validasi   TEXT NOT NULL DEFAULT 'draft' CHECK (status_validasi IN ('draft','tervalidasi')),
    diinput_oleh      INTEGER REFERENCES guru(id),
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_nilai_siswa ON nilai(siswa_id);
CREATE INDEX IF NOT EXISTS idx_nilai_kelas_mapel ON nilai(kelas_id, mata_pelajaran_id);

CREATE TABLE IF NOT EXISTS nilai_rapor (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id          INTEGER NOT NULL REFERENCES siswa(id),
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id),
    semester_id       INTEGER NOT NULL REFERENCES semester(id),
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    nilai_akhir       REAL,
    predikat          TEXT,
    catatan_wali_kelas TEXT,
    wali_kelas_id     INTEGER REFERENCES guru(id),
    status_kirim      TEXT NOT NULL DEFAULT 'draft' CHECK (status_kirim IN ('draft','selesai','dicetak')),
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_nilai_rapor_siswa ON nilai_rapor(siswa_id, semester_id);

CREATE TABLE IF NOT EXISTS rapor_arsip (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id    INTEGER NOT NULL REFERENCES siswa(id),
    semester_id INTEGER NOT NULL REFERENCES semester(id),
    file_url    TEXT,
    dicetak_pada TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 6. BK (BIMBINGAN KONSELING)
-- ============================================================

CREATE TABLE IF NOT EXISTS pengaduan (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id       INTEGER NOT NULL REFERENCES siswa(id),
    kategori       TEXT NOT NULL CHECK (kategori IN ('perilaku','kasus')),
    deskripsi      TEXT NOT NULL,
    bukti_url      TEXT,
    dilaporkan_oleh INTEGER REFERENCES guru(id),
    status         TEXT NOT NULL DEFAULT 'baru' CHECK (status IN ('baru','ditindaklanjuti','selesai')),
    tindak_lanjut  TEXT,
    created_at     TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS jadwal_konseling (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id  INTEGER REFERENCES siswa(id),
    guru_bk_id INTEGER REFERENCES guru(id),
    tanggal   TEXT NOT NULL,
    jam       TEXT,
    jenis     TEXT NOT NULL CHECK (jenis IN ('individu','kelompok','online')),
    status    TEXT NOT NULL DEFAULT 'dijadwalkan' CHECK (status IN ('dijadwalkan','selesai','dibatalkan')),
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS konseling (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    jadwal_id INTEGER REFERENCES jadwal_konseling(id),
    siswa_id  INTEGER NOT NULL REFERENCES siswa(id),
    guru_bk_id INTEGER NOT NULL REFERENCES guru(id),
    tanggal   TEXT NOT NULL,
    catatan   TEXT,
    tindak_lanjut TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS bakat_minat (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id  INTEGER NOT NULL REFERENCES siswa(id),
    jenis     TEXT NOT NULL CHECK (jenis IN ('akademik','olahraga','seni','keagamaan','organisasi','lainnya')),
    deskripsi TEXT,
    catatan_pengembangan TEXT,
    guru_bk_id INTEGER NOT NULL REFERENCES guru(id),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 7. KENAIKAN KELAS & ALUMNI
-- ============================================================

CREATE TABLE IF NOT EXISTS kenaikan_kelas (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id         INTEGER NOT NULL REFERENCES siswa(id),
    dari_kelas_id    INTEGER NOT NULL REFERENCES kelas(id),
    ke_kelas_id      INTEGER REFERENCES kelas(id),
    tahun_ajaran_id  INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    status           TEXT NOT NULL CHECK (status IN ('naik','tidak_naik','lulus')),
    no_surat_keputusan TEXT,
    tanggal_keputusan TEXT,
    created_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS alumni (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id   INTEGER NOT NULL REFERENCES siswa(id) UNIQUE,
    tahun_lulus INTEGER NOT NULL,
    kontak     TEXT,
    catatan    TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 8. PENGATURAN TAMPILAN LOGIN
-- ============================================================

CREATE TABLE IF NOT EXISTS pengaturan (
    key        TEXT PRIMARY KEY,
    value      TEXT,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT OR IGNORE INTO pengaturan (key, value) VALUES
  ('hero_title', 'Sistem Informasi Madrasah'),
  ('hero_subtitle', 'MTs Garut'),
  ('logo_url', ''),
  ('background_url', '');
