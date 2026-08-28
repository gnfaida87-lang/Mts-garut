-- Migration 0033: Buat ulang tabel guru_mapel_kelas (jika belum ada) via migrasi bernomor
-- Sebelumnya tabel ini hanya dibuat oleh migrasi manual legacy (v4.sql) yang dijalankan
-- sekali ke database lama. Untuk memastikan deploy otomatis ke `mts-garut-db` mencakup
-- tabel ini (modul Master Data -> Guru Mapel Kelas), kita definisikan ulang di sini.

CREATE TABLE IF NOT EXISTS guru_mapel_kelas (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id           INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id) ON DELETE CASCADE,
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(guru_id, mata_pelajaran_id, kelas_id)
);

CREATE INDEX IF NOT EXISTS idx_gmk_guru       ON guru_mapel_kelas(guru_id);
CREATE INDEX IF NOT EXISTS idx_gmk_mapel      ON guru_mapel_kelas(mata_pelajaran_id);
CREATE INDEX IF NOT EXISTS idx_gmk_kelas      ON guru_mapel_kelas(kelas_id);
CREATE INDEX IF NOT EXISTS idx_gmk_guru_mapel ON guru_mapel_kelas(guru_id, mata_pelajaran_id);
CREATE INDEX IF NOT EXISTS idx_gmk_guru_kelas ON guru_mapel_kelas(guru_id, kelas_id);

-- Seed data lama: gabungkan guru_mapel x guru_kelas untuk kombinasi valid di mapel_kelas.
-- Dipakai agar data yang sudah ada dari pengaturan Asatidz tetap tampil.
INSERT OR IGNORE INTO guru_mapel_kelas (guru_id, mata_pelajaran_id, kelas_id)
SELECT DISTINCT gm.guru_id, gm.mata_pelajaran_id, gk.kelas_id
FROM guru_mapel gm
INNER JOIN guru_kelas gk ON gm.guru_id = gk.guru_id
INNER JOIN mapel_kelas mk ON gm.mata_pelajaran_id = mk.mata_pelajaran_id
                          AND gk.kelas_id = mk.kelas_id;
