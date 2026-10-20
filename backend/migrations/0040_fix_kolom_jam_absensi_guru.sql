-- ============================================
-- MIGRATION 0040: Tambah kolom jam absensi guru (perbaikan)
-- ============================================
-- MASALAH:
--   Tabel `absensi_guru` di database produksi dibangun dari rantai migrasi
--   `migrations/0001_initial.sql`, dan pada rantai itu kolom `jam_masuk` /
--   `jam_keluar` TIDAK PERNAH ditambahkan (kolom tersebut hanya ada di
--   `src/db/schema.sql`, yang tidak dipakai untuk deploy).
--
--   Akibatnya seluruh query absensi guru gagal dengan error
--   `no such column: jam_masuk`, sehingga:
--     - GET /api/public/absensi-hari-ini  -> 500 Internal Server Error
--       (papan Display Absensi tidak pernah menampilkan data)
--     - POST scan QR absensi guru         -> 500 / gagal menyimpan jam
--
-- PERBAIKAN:
--   Tambahkan kedua kolom tersebut. Aman dijalankan berulang
--   (dilewati bila kolom sudah ada).
--
-- Jalankan dengan:
--   npx wrangler d1 execute mts-garut-db --remote --file=./migrations/0040_fix_kolom_jam_absensi_guru.sql

ALTER TABLE absensi_guru ADD COLUMN jam_masuk TEXT;
ALTER TABLE absensi_guru ADD COLUMN jam_keluar TEXT;

-- Selaraskan dengan schema.sql
UPDATE absensi_guru SET jam_masuk = created_at WHERE jam_masuk IS NULL;
