-- ============================================
-- MIGRATION 0038: Pengaturan waktu absensi guru
-- ============================================
-- Admin dapat mengatur jam masuk & jam keluar absensi guru dari UI
-- (tab Pengaturan > Absensi). Nilai disimpan sebagai key/value di tabel
-- `pengaturan` sehingga tidak perlu deploy ulang saat diubah.
--
-- Urutan fallback pada handler scan: tabel `pengaturan` -> env JAM_* -> default.
--
-- Jalankan dengan:
--   npx wrangler d1 execute mts-garut-db --env production --remote --file=./migrations/0038_pengaturan_waktu_absensi_guru.sql

INSERT OR IGNORE INTO pengaturan (key, value) VALUES
    ('absensi_jam_masuk_mulai',    '06:30:00'),
    ('absensi_jam_masuk_selesai',  '10:00:00'),
    ('absensi_jam_keluar_mulai',   '11:00:00'),
    ('absensi_jam_keluar_selesai', '15:00:00');
