import { Env } from '../types';

/**
 * Pengaturan waktu absensi (jam masuk & jam keluar) untuk:
 *  - Guru/WK/KS : scan QR di endpoint `/api/absensi/scan`
 *  - Musyrifah  : scan QR at-Ta'wid di endpoint `/api/musyrifah/absensi/scan`
 *
 * Nilai disimpan sebagai key/value di tabel `pengaturan` sehingga admin dapat
 * mengubahnya dari UI tanpa deploy ulang. Bila key belum ada di database,
 * nilai fallback diambil dari environment variable (perilaku lama), lalu dari
 * konstanta default.
 */
export interface WaktuAbsensi {
  jam_masuk_mulai: string;    // HH:MM:SS
  jam_masuk_selesai: string;  // HH:MM:SS
  jam_keluar_mulai: string;   // HH:MM:SS
  jam_keluar_selesai: string; // HH:MM:SS
}

/** Alias agar pemakaian lebih jelas. */
export type WaktuAbsensiGuru = WaktuAbsensi;
export type WaktuAbsensiMusyrifah = WaktuAbsensi;

/** Key tabel `pengaturan` untuk absensi guru (urutan: masuk mulai, masuk selesai, keluar mulai, keluar selesai). */
export const WAKTU_GURU_KEYS = [
  'absensi_jam_masuk_mulai',
  'absensi_jam_masuk_selesai',
  'absensi_jam_keluar_mulai',
  'absensi_jam_keluar_selesai',
] as const;

/** Key tabel `pengaturan` untuk absensi musyrifah at-Ta'wid. */
export const WAKTU_MUSYRIFAH_KEYS = [
  'dauroh_jam_masuk_mulai',
  'dauroh_jam_masuk_selesai',
  'dauroh_jam_keluar_mulai',
  'dauroh_jam_keluar_selesai',
] as const;

/** Pemetaan nama field API -> key di tabel `pengaturan` (guru). */
export const WAKTU_GURU_FIELD_KEYS: Record<keyof WaktuAbsensi, string> = {
  jam_masuk_mulai: 'absensi_jam_masuk_mulai',
  jam_masuk_selesai: 'absensi_jam_masuk_selesai',
  jam_keluar_mulai: 'absensi_jam_keluar_mulai',
  jam_keluar_selesai: 'absensi_jam_keluar_selesai',
};

/** Pemetaan nama field API -> key di tabel `pengaturan` (musyrifah). */
export const WAKTU_MUSYRIFAH_FIELD_KEYS: Record<keyof WaktuAbsensi, string> = {
  jam_masuk_mulai: 'dauroh_jam_masuk_mulai',
  jam_masuk_selesai: 'dauroh_jam_masuk_selesai',
  jam_keluar_mulai: 'dauroh_jam_keluar_mulai',
  jam_keluar_selesai: 'dauroh_jam_keluar_selesai',
};

const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

/** Apakah string berformat jam valid (HH:MM atau HH:MM:SS). */
export function isValidJam(t: string): boolean {
  return TIME_RE.test(t);
}

/** Normalisasi 'HH:MM' menjadi 'HH:MM:SS'; nilai lain dikembalikan apa adanya (di-trim). */
export function normalizeJam(t: string | null | undefined): string {
  const v = (t ?? '').trim();
  if (/^([01]\d|2[0-3]):[0-5]\d$/.test(v)) return `${v}:00`;
  return v;
}

/** Validasi logika window. Mengembalikan pesan error, atau null bila valid. */
export function validateWaktuAbsensi(w: WaktuAbsensi): string | null {
  for (const field of Object.keys(WAKTU_GURU_FIELD_KEYS) as (keyof WaktuAbsensi)[]) {
    if (!w[field]) return `Field ${field} wajib diisi`;
    if (!isValidJam(w[field])) return 'Format jam harus HH:MM atau HH:MM:SS';
  }
  if (w.jam_masuk_mulai >= w.jam_masuk_selesai) {
    return 'Jam masuk mulai harus lebih awal dari jam masuk selesai';
  }
  if (w.jam_keluar_mulai >= w.jam_keluar_selesai) {
    return 'Jam keluar mulai harus lebih awal dari jam keluar selesai';
  }
  if (w.jam_masuk_selesai > w.jam_keluar_mulai) {
    return 'Window jam masuk tidak boleh tumpang tindih dengan jam keluar';
  }
  return null;
}

/** Baca 4 nilai dari tabel `pengaturan` dengan fallback env lalu default. */
async function loadWaktu(
  env: Env,
  dbKeys: readonly [string, string, string, string],
  fallbacks: readonly (string | undefined)[],
  defaults: readonly [string, string, string, string],
): Promise<WaktuAbsensi> {
  let map: Record<string, string> = {};
  try {
    const rows = await env.DB.prepare(
      'SELECT key, value FROM pengaturan WHERE key IN (?, ?, ?, ?)'
    ).bind(...dbKeys).all<{ key: string; value: string }>();
    for (const r of rows.results) map[r.key] = r.value;
  } catch {
    map = {};
  }
  const val = (i: number) => map[dbKeys[i]] || fallbacks[i] || defaults[i];
  return {
    jam_masuk_mulai: val(0),
    jam_masuk_selesai: val(1),
    jam_keluar_mulai: val(2),
    jam_keluar_selesai: val(3),
  };
}

/** Pengaturan waktu absensi guru (fallback env JAM_*). */
export function getWaktuAbsensiGuru(env: Env): Promise<WaktuAbsensi> {
  return loadWaktu(
    env,
    WAKTU_GURU_KEYS,
    [env.JAM_MASUK_MULAI, env.JAM_MASUK_SELESAI, env.JAM_KELUAR_MULAI, env.JAM_KELUAR_SELESAI],
    ['06:30:00', '10:00:00', '11:00:00', '15:00:00'],
  );
}

/** Pengaturan waktu absensi musyrifah at-Ta'wid (fallback env DAUROH_JAM_*). */
export function getWaktuAbsensiMusyrifah(env: Env): Promise<WaktuAbsensi> {
  return loadWaktu(
    env,
    WAKTU_MUSYRIFAH_KEYS,
    [env.DAUROH_JAM_MASUK_MULAI, env.DAUROH_JAM_MASUK_SELESAI, env.DAUROH_JAM_KELUAR_MULAI, env.DAUROH_JAM_KELUAR_SELESAI],
    ['06:30:00', '07:00:00', '08:00:00', '09:00:00'],
  );
}
