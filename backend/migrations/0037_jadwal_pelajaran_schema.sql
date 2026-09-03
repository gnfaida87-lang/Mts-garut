-- ============================================================
-- MIGRATION 0037 -- perbaiki skema jadwal_pelajaran
-- Target: Cloudflare D1 (SQLite) -- Production
--
-- LATAR BELAKANG:
--   Tabel jadwal_pelajaran di produksi masih memakai skema lama
--   (migrasi 0001) yang punya pembatasan:
--     1. mata_pelajaran_id & guru_id NOT NULL
--        -> menghalangi jadwal KEGIATAN (istirahat/tahfidz/murojaah)
--           yang tidak punya mapel & guru => INSERT NULL => 500.
--     2. tidak ada kolom nama_kegiatan & is_istirahat
--        -> INSERT kegiatan menyebut kolom yang tak ada => 500.
--     3. CHECK hari hanya mengizinkan Senin..Sabtu (tanpa Minggu)
--        -> simpan jadwal hari Minggu => CHECK violation => 500.
--
--   Skema yang benar sudah ada di src/db/schema.sql, tetapi karena
--   SQLite tidak mendukung ALTER untuk mengubah NOT NULL / CHECK,
--   tabel perlu dibuat ulang (recreate + salin data lama).
--
-- AMAN: mempertahankan SEMUA data jadwal (id & isi tetap), idempoten
-- hanya bila dijalankan sekali pada tabel lama.
--
-- Verifikasi setelah apply:
--   PRAGMA table_info(jadwal_pelajaran);  -- mapel & guru nullable,
--                                          ada nama_kegiatan/is_istirahat
--   SELECT COUNT(*) FROM jadwal_pelajaran; -- jumlah baris harus sama
-- ============================================================
-- Catatan: D1 tidak mengizinkan BEGIN TRANSACTION/COMMIT via --file.
-- Seluruh statement dieksekusi sebagai satu batch atomik oleh D1.

-- 1. Buat tabel baru dengan skema yang benar
CREATE TABLE IF NOT EXISTS jadwal_pelajaran_new (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id),
    mata_pelajaran_id INTEGER REFERENCES mata_pelajaran(id),
    guru_id           INTEGER REFERENCES guru(id),
    ruangan_id        INTEGER REFERENCES ruangan(id),
    nama_kegiatan     TEXT,
    is_istirahat      INTEGER NOT NULL DEFAULT 0,
    hari              TEXT NOT NULL CHECK (hari IN (
                            'Sabtu','Minggu','Senin','Selasa','Rabu','Kamis'
                        )),
    jam_mulai         TEXT NOT NULL,
    jam_selesai       TEXT NOT NULL,
    semester_id       INTEGER NOT NULL REFERENCES semester(id),
    status_validasi   TEXT NOT NULL DEFAULT 'draft'
                            CHECK (status_validasi IN ('draft','tervalidasi')),
    gabungan_id       INTEGER REFERENCES kelas_gabungan(id),
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. Salin data lama (pertahankan semua kolom yang ada)
INSERT INTO jadwal_pelajaran_new
    (id, kelas_id, mata_pelajaran_id, guru_id, ruangan_id,
     hari, jam_mulai, jam_selesai, semester_id, status_validasi,
     gabungan_id, created_at, updated_at)
SELECT
    id, kelas_id, mata_pelajaran_id, guru_id, ruangan_id,
    hari, jam_mulai, jam_selesai, semester_id, status_validasi,
    gabungan_id, created_at, updated_at
FROM jadwal_pelajaran;

-- 3. Ganti tabel lama dengan yang baru
DROP TABLE jadwal_pelajaran;
ALTER TABLE jadwal_pelajaran_new RENAME TO jadwal_pelajaran;

-- 4. Buat ulang indeks yang hilang bersama tabel lama
CREATE INDEX IF NOT EXISTS idx_jadwal_kelas    ON jadwal_pelajaran(kelas_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_guru     ON jadwal_pelajaran(guru_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_semester ON jadwal_pelajaran(semester_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_gabungan ON jadwal_pelajaran(gabungan_id);

-- 5. Sinkronkan sequence AUTOINCREMENT
DELETE FROM sqlite_sequence WHERE name = 'jadwal_pelajaran';
INSERT INTO sqlite_sequence (name, seq)
SELECT 'jadwal_pelajaran', COALESCE(MAX(id), 0) FROM jadwal_pelajaran;
