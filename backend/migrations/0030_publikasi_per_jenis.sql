-- Migration 0030: Publikasi nilai per jenis ujian
-- Tabel baru untuk mengontrol publish/unpublish per jenis per semester

CREATE TABLE IF NOT EXISTS publikasi_jenis (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    semester_id INTEGER NOT NULL REFERENCES semester(id),
    jenis       TEXT NOT NULL CHECK (jenis IN ('harian','tugas','pts1','pts2','pas','uts','pat','uas','akhir')),
    is_published INTEGER NOT NULL DEFAULT 0,
    UNIQUE (semester_id, jenis)
);

-- Seed: isi semua jenis untuk semester aktif yang sudah ada dengan default OFF
INSERT OR IGNORE INTO publikasi_jenis (semester_id, jenis, is_published)
SELECT s.id, j.jenis, 0
FROM semester s
CROSS JOIN (
    SELECT 'harian' as jenis UNION ALL SELECT 'tugas' UNION ALL SELECT 'pts1' UNION ALL
    SELECT 'pts2' UNION ALL SELECT 'pas' UNION ALL SELECT 'uts' UNION ALL
    SELECT 'pat' UNION ALL SELECT 'uas' UNION ALL SELECT 'akhir'
) j
WHERE s.is_aktif = 1;
