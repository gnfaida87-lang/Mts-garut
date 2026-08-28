-- Migration 0032: Publikasi nilai per mata pelajaran
-- Kontrol publish/unpublish nilai per mapel per semester per jenis.
-- Digunakan pada halaman Monitoring Nilai untuk modul status kelengkapan
-- nilai (komplit/sebagian/belum upload) per mapel.

CREATE TABLE IF NOT EXISTS publikasi_mapel (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    semester_id        INTEGER NOT NULL REFERENCES semester(id),
    mata_pelajaran_id  INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    jenis              TEXT NOT NULL,
    is_published       INTEGER NOT NULL DEFAULT 0,
    UNIQUE (semester_id, mata_pelajaran_id, jenis)
);

-- Seed opsional: isi default OFF untuk mapel yang sudah punya nilai per semester aktif
INSERT OR IGNORE INTO publikasi_mapel (semester_id, mata_pelajaran_id, jenis, is_published)
SELECT DISTINCT n.semester_id, n.mata_pelajaran_id, n.jenis, 0
FROM nilai n
WHERE n.semester_id IN (SELECT id FROM semester WHERE is_aktif = 1);
