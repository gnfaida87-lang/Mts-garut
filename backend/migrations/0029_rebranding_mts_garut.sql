-- ============================================================
-- Rebranding: PPI -> MTs Garut
-- Update teks tampilan lama di tabel pengaturan (idempotent).
-- Hanya mengubah nilai yang masih memakai branding lama.
-- ============================================================

UPDATE pengaturan
SET value = 'MTs Garut',
    updated_at = datetime('now')
WHERE key = 'hero_subtitle'
  AND value = 'MA / MTs PPI';
