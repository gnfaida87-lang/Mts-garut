-- ============================================
-- MIGRATION 0039: Pengaturan waktu absensi musyrifah (at-Ta'wid)
-- ============================================
-- Admin dapat mengatur jam masuk & jam keluar absensi QR musyrifah dari UI
-- (Modul at-Ta'wid > Waktu Absensi). Nilai disimpan sebagai key/value di tabel
-- `pengaturan` sehingga tidak perlu deploy ulang saat diubah.
--
-- Urutan fallback pada handler scan: tabel `pengaturan` -> env DAUROH_JAM_* -> default.
--
-- Jalankan dengan:
--   npx wrangler d1 execute mts-garut-db --env production --remote --file=./migrations/0039_pengaturan_waktu_absensi_musyrifah.sql

INSERT OR IGNORE INTO pengaturan (key, value) VALUES
    ('dauroh_jam_masuk_mulai',    '06:30:00'),
    ('dauroh_jam_masuk_selesai',  '07:00:00'),
    ('dauroh_jam_keluar_mulai',   '08:00:00'),
    ('dauroh_jam_keluar_selesai', '09:00:00');
