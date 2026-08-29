-- Migration 0034: Seed pengaturan tampilan login yang konsisten
-- Memastikan tabel `pengaturan` selalu memiliki nilai default untuk tampilan
-- halaman login (hero_title, hero_subtitle, logo_url, background_url).
-- INSERT OR IGNORE: hanya menyisipkan key yang belum ada, TIDAK menimpa nilai
-- yang sudah diubah admin. Dengan begitu, judul yang tampil selalu datang dari
-- backend (bisa diubah di menu admin), bukan fallback hardcoded di kode frontend.

INSERT OR IGNORE INTO pengaturan (key, value) VALUES
  ('hero_title', 'Sistem Informasi MTs Persis Garut'),
  ('hero_subtitle', 'Kelola data akademik, absensi, nilai, rapor, dan bimbingan konseling dalam satu platform.'),
  ('logo_url', ''),
  ('background_url', '');
