-- ============================================================
-- MIGRATION 0036 — tabel kegiatan_tetap (dapat dikelola via UI)
-- Salinan isi src/db/migrations/v11.sql agar diterapkan otomatis
-- oleh CI: wrangler d1 migrations apply
-- Target: Cloudflare D1 (SQLite) — Production
--
-- Sebelumnya tabel kegiatan_tetap hanya dibuat lewat v11.sql
-- (folder src/db/migrations) yang TIDAK tercakup alur migrasi
-- 0001-0035 di folder migrations/, sehingga tabel ini tidak ada
-- di database produksi mts-garut-db → route referensi (penjadwalan.ts)
-- gagal dengan 'no such table: kegiatan_tetap' → HTTP 500.
--
-- Idempoten: CREATE TABLE IF NOT EXISTS + INSERT OR IGNORE,
-- tidak mengubah/menghapus data lain.
--
-- Verifikasi setelah apply:
--   SELECT * FROM kegiatan_tetap ORDER BY urutan;
-- ============================================================

CREATE TABLE IF NOT EXISTS kegiatan_tetap (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    nama    TEXT NOT NULL UNIQUE,
    tipe    TEXT NOT NULL DEFAULT 'kegiatan' CHECK (tipe IN ('kegiatan','istirahat')),
    urutan  INTEGER NOT NULL DEFAULT 0
);

-- Seed default (INSERT OR IGNORE agar tidak menimpa jika sudah ada)
INSERT OR IGNORE INTO kegiatan_tetap (nama, tipe, urutan) VALUES
    ('Istirahat RG',          'istirahat', 1),
    ('Istirahat UG',          'istirahat', 2),
    ('Tahfidz & Tahsin',      'kegiatan',  3),
    ('Murojaah',              'kegiatan',  4),
    ("Ba'at",                 'kegiatan',  5),
    ('Shalat Dzuhur Berjamaah','kegiatan', 6);
