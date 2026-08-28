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
-- CATATAN: pakai VALUES clause (bukan UNION ALL) karena D1 membatasi compound SELECT
-- hanya 3 term (sqlite3_limit SQLITE_LIMIT_COMPOUND_SELECT = 3). UNION ALL 9 term
-- memicu error "too many terms in compound SELECT".
INSERT OR IGNORE INTO publikasi_jenis (semester_id, jenis, is_published)
SELECT s.id, j.column1, 0
FROM semester s
CROSS JOIN (
    VALUES ('harian'), ('tugas'), ('pts1'), ('pts2'),
           ('pas'), ('uts'), ('pat'), ('uas'), ('akhir')
) j
WHERE s.is_aktif = 1;
