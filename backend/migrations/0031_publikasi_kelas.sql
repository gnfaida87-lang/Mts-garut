-- Migration 0031: Publikasi nilai per kelas
-- Kontrol publish/unpublish nilai per kelas per semester.
-- Jika publikasi global OFF, siswa hanya bisa melihat nilai
-- jika kelasnya diaktifkan di tabel ini.

CREATE TABLE IF NOT EXISTS publikasi_kelas (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    semester_id  INTEGER NOT NULL REFERENCES semester(id),
    kelas_id     INTEGER NOT NULL REFERENCES kelas(id),
    is_published INTEGER NOT NULL DEFAULT 0,
    UNIQUE (semester_id, kelas_id)
);

-- Seed: isi semua kelas untuk semester aktif dengan default OFF.
-- Pakai subquery biasa (bukan UNION ALL) agar kompatibel dengan limit
-- compound SELECT di Cloudflare D1 (maks 3 term).
INSERT OR IGNORE INTO publikasi_kelas (semester_id, kelas_id, is_published)
SELECT s.id, k.id, 0
FROM semester s
JOIN kelas k ON k.tahun_ajaran_id = s.tahun_ajaran_id
WHERE s.is_aktif = 1;
