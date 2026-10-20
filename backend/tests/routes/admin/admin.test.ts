import { describe, it, expect, vi } from 'vitest';
import { handleDashboard } from '../../../src/routes/admin/dashboard';
import { handleAdminMasterData } from '../../../src/routes/admin/master_data';
import { handleAdminUsers, handleHakAkses } from '../../../src/routes/admin/users';
import { handleBackup, handleRestore, handleLogAktivitas } from '../../../src/routes/admin/system';
import { handleAdminAbsensi } from '../../../src/routes/admin/absensi';
import { handleAdminNilai } from '../../../src/routes/admin/nilai';
import { handleAdminRapor } from '../../../src/routes/admin/rapor';
import { handlePengaturanTampilan } from '../../../src/routes/admin/pengaturan_tampilan';
import { handleAdminDauroh } from '../../../src/routes/admin/dauroh';
import { handleHealth } from '../../../src/routes/health';

function makeDb() {
  const first = vi.fn();
  const all = vi.fn();
  const run = vi.fn().mockResolvedValue({ meta: { last_row_id: 1, changes: 1 } });
  const bind = vi.fn(() => ({ first, all, run }));
  const stmt = { first, all, run, bind };
  const prepare = vi.fn(() => stmt);
  return { DB: { prepare }, first, all, run, bind, stmt };
}

const adminUser = { sub: 1, username: 'admin', role: 'admin' as const, guru_id: null };
const nonAdminUser = { sub: 2, username: 'guru', role: 'guru_mapel_wali_kelas' as const, guru_id: 5 };

function makeUrl(path: string, search = ''): URL {
  return new URL(`http://localhost${path}${search ? '?' + search : ''}`);
}

function makeGet(path: string, search?: string): Request {
  return new Request(makeUrl(path, search), { method: 'GET' });
}

function makePost(path: string, body: unknown): Request {
  return new Request(makeUrl(path), { method: 'POST', body: JSON.stringify(body), headers: { 'Content-Type': 'application/json' } });
}

function makePut(path: string, body: unknown): Request {
  return new Request(makeUrl(path), { method: 'PUT', body: JSON.stringify(body), headers: { 'Content-Type': 'application/json' } });
}

function makeDelete(path: string): Request {
  return new Request(makeUrl(path), { method: 'DELETE' });
}

describe('Admin Routes', () => {
  describe('Dashboard', () => {
    it('should return ringkasan with 6 stats', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 10 });
      db.all.mockResolvedValue({ results: [] });

      const res = await handleDashboard(db);
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
      expect(body.data.ringkasan).toHaveProperty('guru');
      expect(body.data.ringkasan).toHaveProperty('siswa');
      expect(body.data.ringkasan).toHaveProperty('kelas');
      expect(body.data.ringkasan).toHaveProperty('absensi_hari_ini');
      expect(body.data.ringkasan).toHaveProperty('nilai');
      expect(body.data.ringkasan).toHaveProperty('jadwal');
    });
  });

  describe('Master Data CRUD', () => {
    it('should list tahun-ajaran with pagination', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 2 });
      db.all.mockResolvedValue({ results: [{ id: 1, nama: '2025/2026' }, { id: 2, nama: '2026/2027' }] });

      const req = makeGet('/api/admin/tahun-ajaran');
      const res = await handleAdminMasterData(req, db, adminUser, ['api', 'admin', 'tahun-ajaran'], makeUrl('/api/admin/tahun-ajaran'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.items).toHaveLength(2);
      expect(body.data.pagination.total).toBe(2);
    });

    it('should reject unknown resource', async () => {
      const db = makeDb();
      const req = makeGet('/api/admin/unknown');
      const res = await handleAdminMasterData(req, db, adminUser, ['api', 'admin', 'unknown'], makeUrl('/api/admin/unknown'));
      expect(res.status).toBe(400);
    });

    it('should create a new entity', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);
      db.run.mockResolvedValue({ meta: { last_row_id: 1 } });

      const req = makePost('/api/admin/jurusan', { nama: 'IPA', kode: 'IPA' });
      const res = await handleAdminMasterData(req, db, adminUser, ['api', 'admin', 'jurusan'], makeUrl('/api/admin/jurusan'));
      expect(res.status).toBe(201);
    });

    it('should get entity by id', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, nama: 'IPA', kode: 'IPA' });

      const req = makeGet('/api/admin/jurusan/1');
      const res = await handleAdminMasterData(req, db, adminUser, ['api', 'admin', 'jurusan', '1'], makeUrl('/api/admin/jurusan/1'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.id).toBe(1);
    });

    it('should update an entity', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 });
      db.run.mockResolvedValue({ meta: { changes: 1 } });

      const req = makePut('/api/admin/jurusan/1', { nama: 'IPS' });
      const res = await handleAdminMasterData(req, db, adminUser, ['api', 'admin', 'jurusan', '1'], makeUrl('/api/admin/jurusan/1'));
      expect(res.status).toBe(200);
    });

    it('should delete an entity', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 });

      const req = makeDelete('/api/admin/jurusan/1');
      const res = await handleAdminMasterData(req, db, adminUser, ['api', 'admin', 'jurusan', '1'], makeUrl('/api/admin/jurusan/1'));
      expect(res.status).toBe(200);
    });
  });

  describe('Users & Hak Akses', () => {
    it('should create user with hashed password', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);
      db.run.mockResolvedValue({ meta: { last_row_id: 1 } });

      const req = makePost('/api/admin/users', { username: 'newguru', password: 'secret123', role: 'guru_mapel_wali_kelas' });
      const res = await handleAdminUsers(req, db, adminUser, ['api', 'admin', 'users'], makeUrl('/api/admin/users'));
      expect(res.status).toBe(201);
    });

    it('should reject invalid role', async () => {
      const db = makeDb();
      const req = makePost('/api/admin/users', { username: 'newguru', password: 'secret123', role: 'invalid_role' });
      const res = await handleAdminUsers(req, db, adminUser, ['api', 'admin', 'users'], makeUrl('/api/admin/users'));
      expect(res.status).toBe(400);
    });

    it('should delete user', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 });

      const req = makeDelete('/api/admin/users/1');
      const res = await handleAdminUsers(req, db, adminUser, ['api', 'admin', 'users', '1'], makeUrl('/api/admin/users/1'));
      expect(res.status).toBe(200);
    });

    it('should list hak akses', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, role: 'admin', modul: 'nilai', aksi: 'view' }] });

      const req = makeGet('/api/admin/hak-akses');
      const res = await handleHakAkses(req, db, adminUser, ['api', 'admin', 'hak-akses']);
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data).toHaveLength(1);
    });

    it('should create hak akses', async () => {
      const db = makeDb();
      db.run.mockResolvedValue({ meta: { changes: 1 } });

      const req = makePost('/api/admin/hak-akses', { role: 'guru_bk', modul: 'pengaduan', aksi: 'view' });
      const res = await handleHakAkses(req, db, adminUser, ['api', 'admin', 'hak-akses']);
      expect(res.status).toBe(201);
    });
  });

  describe('System (Backup/Restore/Log)', () => {
    it('should backup all tables', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, username: 'admin' }] });
      db.run.mockResolvedValue({ meta: { changes: 1 } });

      const req = makePost('/api/admin/backup');
      const res = await handleBackup(req, db, adminUser);
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.tables).toContain('users');
    });

    it('should restore database', async () => {
      const db = makeDb();
      db.run.mockResolvedValue({ meta: { changes: 1 } });

      const req = makePost('/api/admin/restore', { data: { users: [{ id: 1, username: 'admin' }] } });
      const res = await handleRestore(req, db, adminUser);
      expect(res.status).toBe(200);
    });

    it('should list log aktivitas', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 1 });
      db.all.mockResolvedValue({ results: [{ id: 1, aksi: 'login', username: 'admin' }] });

      const req = makeGet('/api/admin/log-aktivitas');
      const res = await handleLogAktivitas(req, db, adminUser, makeUrl('/api/admin/log-aktivitas'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.items).toHaveLength(1);
    });
  });

  describe('Absensi Monitoring', () => {
    it('should list absensi guru', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 1 });
      db.all.mockResolvedValue({ results: [{ id: 1, guru_nama: 'Guru A', status: 'hadir' }] });

      const req = makeGet('/api/admin/absensi/guru');
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/guru'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.items).toHaveLength(1);
    });

    it('should list absensi siswa with filters', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 2 });
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', status: 'hadir' }] });

      const req = makeGet('/api/admin/absensi/siswa?kelas_id=1&tanggal=2026-07-27');
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/siswa', 'kelas_id=1&tanggal=2026-07-27'));
      expect(res.status).toBe(200);
    });

    it('should return rekap absensi', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ status: 'hadir', count: 20 }] });

      const req = makeGet('/api/admin/absensi/rekap');
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/rekap'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data).toHaveProperty('siswa');
      expect(body.data).toHaveProperty('guru');
    });

    it('should return 400 for unknown endpoint', async () => {
      const db = makeDb();
      const req = makeGet('/api/admin/absensi/unknown');
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/unknown'));
      expect(res.status).toBe(400);
    });

    it('should update absensi guru via PUT', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, tanggal: '2026-08-18' });

      const req = makePut('/api/admin/absensi/guru/1', { jam_masuk: '07:00', jam_keluar: '14:30', status: 'hadir' });
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/guru/1'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.updated).toBe(true);
    });

    it('should return 404 when absensi guru not found', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);

      const req = makePut('/api/admin/absensi/guru/999', { status: 'izin' });
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/guru/999'));
      expect(res.status).toBe(404);
    });

    it('should reject invalid time format in absensi guru PUT', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, tanggal: '2026-08-18' });

      const req = makePut('/api/admin/absensi/guru/1', { jam_masuk: '25:99' });
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/guru/1'));
      expect(res.status).toBe(400);
    });

    it('should return pengaturan waktu absensi with defaults', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [
        { key: 'absensi_jam_masuk_mulai', value: '07:00:00' },
        { key: 'absensi_jam_keluar_selesai', value: '16:00:00' },
      ] });

      const req = makeGet('/api/admin/absensi/pengaturan-waktu');
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/pengaturan-waktu'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.jam_masuk_mulai).toBe('07:00:00');
      expect(body.data.jam_keluar_selesai).toBe('16:00:00');
      // key yang tidak ada di mock memakai default
      expect(body.data.jam_masuk_selesai).toBe('10:00:00');
      expect(body.data.jam_keluar_mulai).toBe('11:00:00');
    });

    it('should save pengaturan waktu absensi via PUT', async () => {
      const db = makeDb();

      const req = makePut('/api/admin/absensi/pengaturan-waktu', {
        jam_masuk_mulai: '07:00',
        jam_masuk_selesai: '09:30',
        jam_keluar_mulai: '12:00',
        jam_keluar_selesai: '16:00',
      });
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/pengaturan-waktu'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.jam_masuk_mulai).toBe('07:00:00');
      expect(body.data.jam_keluar_selesai).toBe('16:00:00');
      expect(db.run).toHaveBeenCalledTimes(5); // 4 key + 1 log aktivitas
    });

    it('should reject invalid time format in pengaturan waktu PUT', async () => {
      const db = makeDb();

      const req = makePut('/api/admin/absensi/pengaturan-waktu', {
        jam_masuk_mulai: '25:99',
        jam_masuk_selesai: '10:00',
        jam_keluar_mulai: '11:00',
        jam_keluar_selesai: '15:00',
      });
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/pengaturan-waktu'));
      expect(res.status).toBe(400);
    });

    it('should reject overlapping window in pengaturan waktu PUT', async () => {
      const db = makeDb();

      const req = makePut('/api/admin/absensi/pengaturan-waktu', {
        jam_masuk_mulai: '06:30',
        jam_masuk_selesai: '11:30',
        jam_keluar_mulai: '11:00',
        jam_keluar_selesai: '15:00',
      });
      const res = await handleAdminAbsensi(req, db, adminUser, makeUrl('/api/admin/absensi/pengaturan-waktu'));
      expect(res.status).toBe(400);
    });
  });

  describe('Dauroh Absensi Monitoring', () => {
    it('should list monitoring absensi musyrifah', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ nipmus: 'M001', nama: 'Mufidah', belum_absen: 1 }] });
      db.first.mockResolvedValue({ total: 1, hadir: 0, izin: 0, sakit: 0, alpha: 0, belum_absen: 1 });

      const req = makeGet('/api/admin/dauroh/monitoring/absensi?tanggal=2026-08-18');
      const pathParts = ['api', 'admin', 'dauroh', 'monitoring', 'absensi'];
      const res = await handleAdminDauroh(req, db, adminUser, pathParts, makeUrl('/api/admin/dauroh/monitoring/absensi', 'tanggal=2026-08-18'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.data).toHaveLength(1);
    });

    it('should update absensi musyrifah via PUT', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, tanggal: '2026-08-18' });

      const req = makePut('/api/admin/dauroh/monitoring/absensi/1', { waktu_masuk: '06:40', waktu_keluar: '08:30', status: 'hadir' });
      const pathParts = ['api', 'admin', 'dauroh', 'monitoring', 'absensi', '1'];
      const res = await handleAdminDauroh(req, db, adminUser, pathParts, makeUrl('/api/admin/dauroh/monitoring/absensi/1'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.updated).toBe(true);
    });

    it('should reject invalid time format in absensi musyrifah PUT', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, tanggal: '2026-08-18' });

      const req = makePut('/api/admin/dauroh/monitoring/absensi/1', { waktu_masuk: '25:99' });
      const pathParts = ['api', 'admin', 'dauroh', 'monitoring', 'absensi', '1'];
      const res = await handleAdminDauroh(req, db, adminUser, pathParts, makeUrl('/api/admin/dauroh/monitoring/absensi/1'));
      expect(res.status).toBe(400);
    });

    it('should return 404 when absensi musyrifah not found', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);

      const req = makePut('/api/admin/dauroh/monitoring/absensi/999', { status: 'izin' });
      const pathParts = ['api', 'admin', 'dauroh', 'monitoring', 'absensi', '999'];
      const res = await handleAdminDauroh(req, db, adminUser, pathParts, makeUrl('/api/admin/dauroh/monitoring/absensi/999'));
      expect(res.status).toBe(404);
    });

    it('should return pengaturan waktu absensi musyrifah with defaults', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [
        { key: 'dauroh_jam_masuk_mulai', value: '07:00:00' },
        { key: 'dauroh_jam_keluar_selesai', value: '10:00:00' },
      ] });

      const req = makeGet('/api/admin/dauroh/pengaturan-waktu');
      const pathParts = ['api', 'admin', 'dauroh', 'pengaturan-waktu'];
      const res = await handleAdminDauroh(req, db, adminUser, pathParts, makeUrl('/api/admin/dauroh/pengaturan-waktu'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.jam_masuk_mulai).toBe('07:00:00');
      expect(body.data.jam_keluar_selesai).toBe('10:00:00');
      // key yang tidak ada di mock memakai default
      expect(body.data.jam_masuk_selesai).toBe('07:00:00');
      expect(body.data.jam_keluar_mulai).toBe('08:00:00');
    });

    it('should save pengaturan waktu absensi musyrifah via PUT', async () => {
      const db = makeDb();

      const req = makePut('/api/admin/dauroh/pengaturan-waktu', {
        jam_masuk_mulai: '07:00',
        jam_masuk_selesai: '07:30',
        jam_keluar_mulai: '09:00',
        jam_keluar_selesai: '10:00',
      });
      const pathParts = ['api', 'admin', 'dauroh', 'pengaturan-waktu'];
      const res = await handleAdminDauroh(req, db, adminUser, pathParts, makeUrl('/api/admin/dauroh/pengaturan-waktu'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.jam_masuk_mulai).toBe('07:00:00');
      expect(body.data.jam_keluar_selesai).toBe('10:00:00');
      expect(db.run).toHaveBeenCalledTimes(5); // 4 key + 1 log aktivitas
    });

    it('should reject invalid time format in pengaturan waktu musyrifah PUT', async () => {
      const db = makeDb();

      const req = makePut('/api/admin/dauroh/pengaturan-waktu', {
        jam_masuk_mulai: '25:99',
        jam_masuk_selesai: '07:00',
        jam_keluar_mulai: '08:00',
        jam_keluar_selesai: '09:00',
      });
      const pathParts = ['api', 'admin', 'dauroh', 'pengaturan-waktu'];
      const res = await handleAdminDauroh(req, db, adminUser, pathParts, makeUrl('/api/admin/dauroh/pengaturan-waktu'));
      expect(res.status).toBe(400);
    });

    it('should reject overlapping window in pengaturan waktu musyrifah PUT', async () => {
      const db = makeDb();

      const req = makePut('/api/admin/dauroh/pengaturan-waktu', {
        jam_masuk_mulai: '06:30',
        jam_masuk_selesai: '09:30',
        jam_keluar_mulai: '08:00',
        jam_keluar_selesai: '10:00',
      });
      const pathParts = ['api', 'admin', 'dauroh', 'pengaturan-waktu'];
      const res = await handleAdminDauroh(req, db, adminUser, pathParts, makeUrl('/api/admin/dauroh/pengaturan-waktu'));
      expect(res.status).toBe(400);
    });
  });

  describe('Nilai Monitoring', () => {
    it('should list nilai with filters', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 5 });
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', nilai: 85 }] });

      const req = makeGet('/api/admin/nilai?kelas_id=1&jenis=harian');
      const res = await handleAdminNilai(req, db, adminUser, makeUrl('/api/admin/nilai', 'kelas_id=1&jenis=harian'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.items).toHaveLength(1);
    });

    it('should validasi nilai', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 });
      db.run.mockResolvedValue({ meta: { changes: 1 } });

      const req = makePut('/api/admin/nilai/1/validasi', {});
      const res = await handleAdminNilai(req, db, adminUser, makeUrl('/api/admin/nilai/1/validasi'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.status_validasi).toBe('tervalidasi');
    });

    it('should return 404 validasi non-existent nilai', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);

      const req = makePut('/api/admin/nilai/999/validasi', {});
      const res = await handleAdminNilai(req, db, adminUser, makeUrl('/api/admin/nilai/999/validasi'));
      expect(res.status).toBe(404);
    });
  });

  describe('Rapor Monitoring', () => {
    it('should list rapor', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 3 });
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', status_kirim: 'draft' }] });

      const req = makeGet('/api/admin/rapor');
      const res = await handleAdminRapor(req, db, adminUser, makeUrl('/api/admin/rapor'));
      expect(res.status).toBe(200);
    });

    it('should cetak rapor', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 });
      db.first.mockResolvedValue({ siswa_id: 1, kelas_id: 1, semester_id: 1 });
      db.run.mockResolvedValue({ meta: { changes: 1 } });

      const req = makePost('/api/admin/rapor/1/cetak', {});
      const res = await handleAdminRapor(req, db, adminUser, makeUrl('/api/admin/rapor/1/cetak'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.message).toContain('dicetak');
    });

    it('should return arsip rapor', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 2 });
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A' }] });

      const req = makeGet('/api/admin/rapor/arsip');
      const res = await handleAdminRapor(req, db, adminUser, makeUrl('/api/admin/rapor/arsip'));
      expect(res.status).toBe(200);
    });
  });

  describe('Pengaturan Tampilan', () => {
    it('should list pengaturan', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ key: 'hero_title', value: 'Selamat Datang' }] });

      const req = makeGet('/api/admin/pengaturan-tampilan');
      const res = await handlePengaturanTampilan(req, db, makeUrl('/api/admin/pengaturan-tampilan'));
      expect(res.status).toBe(200);
    });

    it('should update pengaturan', async () => {
      const db = makeDb();
      db.run.mockResolvedValue({ meta: { changes: 1 } });

      const req = makePut('/api/admin/pengaturan-tampilan', { hero_title: 'Test', logo_url: 'logo.png' });
      const res = await handlePengaturanTampilan(req, db, makeUrl('/api/admin/pengaturan-tampilan'));
      expect(res.status).toBe(200);
    });
  });

  describe('Health Check', () => {
    it('should return ok when DB is connected', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ ok: 1 });

      const res = await handleHealth(db);
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.status).toBe('ok');
      expect(body.data.database).toBe('connected');
      expect(body.data).toHaveProperty('timestamp');
      expect(body.data).toHaveProperty('version');
    });

    it('should return degraded when DB query fails', async () => {
      const db = makeDb();
      db.first.mockRejectedValue(new Error('DB connection failed'));

      const res = await handleHealth(db);
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.status).toBe('degraded');
      expect(body.data.database).toBe('disconnected');
    });

    it('should return degraded when DB returns unexpected result', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);

      const res = await handleHealth(db);
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.status).toBe('degraded');
      expect(body.data.database).toBe('error');
    });
  });
});