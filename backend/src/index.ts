import bcrypt from 'bcryptjs';
import { authMiddleware, generateToken, generateRefreshToken, verifyRefreshToken } from './middleware/auth';
import { generalRateLimit, bruteForceCheck, bruteForceRecordFailure, bruteForceRecordSuccess } from './middleware/rate_limit';
import { validateApiKey } from './middleware/api_key';
import { createSession, validateSession, revokeSession, hashToken } from './middleware/session';
import { Env, Role, UserPayload } from './types';
import { json, success, error, unauthorized, cors, setCorsOrigin, resolveCorsOrigin } from './utils/response';
import { handleAdminMasterData, handleMapelKelas, handleGuruMapelAmpu, handleGuruKelasAmpu, handleGuruMapelKelas, handleGuruMapelKelasAll, handleGuruMapelKelasRow, handleGuruByMapelKelas, handleWaliKelasList, handleGuruBKList, handleSiswaTemplate, handleSiswaPreview, handleSiswaBulk, handleMapelTemplate, handleMapelPreview, handleMapelBulk, handleGuruTemplate, handleGuruPreview, handleGuruBulk, handleWaliKelasAssign } from './routes/admin/master_data';
import { handleAdminUsers, handleHakAkses } from './routes/admin/users';
import { handleAdminApiKeys } from './routes/admin/api_keys';
import { handleBackup, handleRestore, handleLogAktivitas } from './routes/admin/system';
import { handlePengaturanTampilan, handleProfilSekolah } from './routes/admin/pengaturan_tampilan';
import { handleDashboard } from './routes/admin/dashboard';
import { handleAdminAbsensi } from './routes/admin/absensi';
import { handleAdminNilai } from './routes/admin/nilai';
import { handleAdminRapor } from './routes/admin/rapor';
import { handleAdminDauroh } from './routes/admin/dauroh';
import { handleMusyrifahRoutes } from './routes/musyrifah/index';
import { handlePenjadwalan } from './routes/wakil_kurikulum/penjadwalan';
import { handleNilaiWK } from './routes/wakil_kurikulum/nilai';
import { handleAbsensiWK } from './routes/wakil_kurikulum/absensi';
import { handleDaurohWK } from './routes/wakil_kurikulum/dauroh';
import { handleKenaikanKelas } from './routes/wakil_kurikulum/kenaikan_kelas';
import { handleLaporanWK } from './routes/wakil_kurikulum/laporan';
import { handleAbsensiGuru } from './routes/guru_mapel_wali_kelas/absensi';
import { handleNilaiGuru } from './routes/guru_mapel_wali_kelas/nilai';
import { handleRaporGuru } from './routes/guru_mapel_wali_kelas/rapor';
import { handlePengaduan } from './routes/guru_mapel_wali_kelas/pengaduan';
import { handleWaliKelas } from './routes/guru_mapel_wali_kelas/wali_kelas';
import { handleMateriGuru } from './routes/guru_mapel_wali_kelas/materi';
import { handlePengaduanBK } from './routes/guru_bk/pengaduan';
import { handleKonselingBK } from './routes/guru_bk/konseling';
import { handleMonitoringBK } from './routes/guru_bk/monitoring';
import { handleLaporanBK } from './routes/guru_bk/laporan';
import { handleDashboardKS } from './routes/kepala_sekolah/dashboard';
import { handleJadwalKS } from './routes/kepala_sekolah/jadwal';
import { handleAbsensiKS } from './routes/kepala_sekolah/absensi';
import { handleNilaiKS } from './routes/kepala_sekolah/nilai';
import { handleDaurohKS } from './routes/kepala_sekolah/dauroh';
import { handleRaporKS } from './routes/kepala_sekolah/rapor';
import { handleBKKS } from './routes/kepala_sekolah/bk';
import { handleLaporanKS } from './routes/kepala_sekolah/laporan';
import { handleSiswaRoutes } from './routes/siswa/index';
import { handleHealth } from './routes/health';
import { handleApiV1Routes } from './routes/api/v1';
import { handlePublicDisplay } from './routes/public/display';

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const requestOrigin = request.headers.get('Origin');
    setCorsOrigin(resolveCorsOrigin(requestOrigin, env));

    if (request.method === 'OPTIONS') return cors();

    const url = new URL(request.url);
    const path = url.pathname;
    const pathParts = path.split('/').filter(Boolean);

    try {
      // General rate limit
      const rateLimitResponse = await generalRateLimit(request, env);
      if (rateLimitResponse) return rateLimitResponse;

      // Health check (no auth required)
      if (path === '/api/health' && request.method === 'GET') {
        return handleHealth(env);
      }

      // Auth routes (no auth required)
      if (path === '/api/auth/login' && request.method === 'POST') {
        return handleLogin(request, env);
      }

      // Login Siswa (no auth required)
      if (path === '/api/auth/login-siswa' && request.method === 'POST') {
        return handleLoginSiswa(request, env);
      }

      // Public pengaturan (GET only, for login page)
      if (path === '/api/pengaturan-tampilan' && request.method === 'GET') {
        const rows = await env.DB.prepare('SELECT key, value FROM pengaturan ORDER BY key').all();
        const map = new Map<string, string>();
        for (const r of rows.results as { key: string; value: string }[]) map.set(r.key, r.value);

        const defaults = [
          ['hero_title', 'Sistem Informasi MTs Persis Garut'],
          ['hero_subtitle', 'Kelola data akademik, absensi, nilai, rapor, dan bimbingan konseling dalam satu platform.'],
          ['logo_url', ''],
          ['background_url', ''],
        ] as const;
        for (const [key, val] of defaults) {
          if (!map.has(key)) map.set(key, val);
        }

        return success(
          Array.from(map.entries()).sort((a, b) => a[0].localeCompare(b[0])).map(([key, value]) => ({ key, value }))
        );
      }

      // Public display kiosk - papan absensi asatidz live (read-only, tanpa auth)
      if (pathParts[0] === 'api' && pathParts[1] === 'public') {
        return handlePublicDisplay(request, env, pathParts);
      }

      // Refresh token (NO auth required - uses refresh_token from body)
      if (path === '/api/auth/refresh' && request.method === 'POST') {
        return handleRefresh(request, env);
      }

      // API v1 routes (Sistem 2 integration - uses X-API-Key, not JWT)
      if (pathParts[0] === 'api' && pathParts[1] === 'v1') {
        return handleApiV1Routes(request, env, pathParts, url);
      }

      // Authenticated routes
      const user = await authMiddleware(request, env);
      if (!user) return unauthorized();

      // QR Scan Absensi (shared untuk guru, WK, KS)
      if (path === '/api/absensi/scan' && request.method === 'POST') {
        return handleScanAbsensi(request, env, user);
      }

      if (path === '/api/auth/me' && request.method === 'GET') {
        return handleMe(user, env);
      }

      // Logout endpoint (requires auth)
      if (path === '/api/auth/logout' && request.method === 'POST') {
        return handleLogout(request, env, user);
      }

      // Admin routes
      if (pathParts[0] === 'api' && pathParts[1] === 'admin') {
        if (user.role !== 'admin') {
          return error('Forbidden: admin only', 403);
        }

        const subPath = pathParts.slice(2).join('/');

        // Mapel bulk endpoints (before master CRUD to avoid capture)
        if (subPath === 'mata-pelajaran/template' && request.method === 'GET') {
          return handleMapelTemplate(request, env);
        }
        if (subPath === 'mata-pelajaran/preview' && request.method === 'POST') {
          return handleMapelPreview(request, env);
        }
        if (subPath === 'mata-pelajaran/bulk' && request.method === 'POST') {
          return handleMapelBulk(request, env, user);
        }

        // Guru bulk endpoints (before master CRUD to avoid capture)
        if (subPath === 'guru/template' && request.method === 'GET') {
          return handleGuruTemplate(request, env);
        }
        if (subPath === 'guru/preview' && request.method === 'POST') {
          return handleGuruPreview(request, env);
        }
        if (subPath === 'guru/bulk' && request.method === 'POST') {
          return handleGuruBulk(request, env, user);
        }

        // Siswa bulk endpoints (before master CRUD to avoid capture)
        if (subPath === 'siswa/template' && request.method === 'GET') {
          return handleSiswaTemplate(env);
        }
        if (subPath === 'siswa/preview' && request.method === 'POST') {
          return handleSiswaPreview(request, env);
        }
        if (subPath === 'siswa/bulk' && request.method === 'POST') {
          return handleSiswaBulk(request, env, user);
        }

        // Master data CRUD: /api/admin/:resource or /api/admin/:resource/:id
        const masterResources = ['tahun-ajaran', 'semester', 'jurusan', 'tingkat', 'kelas', 'mata-pelajaran', 'guru', 'siswa', 'ruangan'];
        if (masterResources.includes(pathParts[2] || '')) {
          return handleAdminMasterData(request, env, user, pathParts, url);
        }

        // Guru associations
        if (subPath.startsWith('guru-mapel-kelas/guru-by-mapel-kelas')) {
          return handleGuruByMapelKelas(request, env, url);
        }
        if (subPath === 'guru-mapel-kelas' && (request.method === 'GET' || request.method === 'POST')) {
          return handleGuruMapelKelasAll(request, env, user, url);
        }
        if (subPath.startsWith('guru-mapel-kelas/') && (request.method === 'PUT' || request.method === 'DELETE')) {
          return handleGuruMapelKelasRow(request, env, user, pathParts);
        }
        if (subPath.startsWith('guru-mapel-kelas/')) {
          return handleGuruMapelKelas(request, env, user, pathParts);
        }
        if (subPath.startsWith('guru-mapel/')) {
          return handleGuruMapelAmpu(request, env, user, pathParts);
        }
        if (subPath.startsWith('guru-kelas/')) {
          return handleGuruKelasAmpu(request, env, user, pathParts);
        }
        if (subPath.startsWith('guru-wali-kelas/')) {
          return handleWaliKelasAssign(request, env, user, pathParts);
        }

        // Wali Kelas & Guru BK list (read-only)
        if (subPath === 'wali-kelas') {
          return handleWaliKelasList(request, env, user);
        }
        if (subPath === 'guru-bk-list') {
          return handleGuruBKList(request, env, user);
        }

        // Mapel-Kelas association
        if (subPath.startsWith('mapel-kelas/')) {
          return handleMapelKelas(request, env, user, pathParts);
        }

        // Users & Hak Akses
        if (subPath === 'users' || subPath.startsWith('users/')) {
          return handleAdminUsers(request, env, user, pathParts, url);
        }
        if (subPath === 'hak-akses' || subPath.startsWith('hak-akses/')) {
          return handleHakAkses(request, env, user, pathParts);
        }

        // API Keys
        if (subPath === 'api-keys' || subPath.startsWith('api-keys/')) {
          return handleAdminApiKeys(request, env, user, pathParts, url);
        }

        // System
        if (subPath === 'dashboard') return handleDashboard(env);
        if (subPath === 'backup') return handleBackup(request, env, user);
        if (subPath === 'restore') return handleRestore(request, env, user);
        if (subPath === 'log-aktivitas') return handleLogAktivitas(request, env, user, url);
        if (subPath === 'profil') return handleProfilSekolah(request, env, user);
        if (subPath === 'pengaturan-tampilan') return handlePengaturanTampilan(request, env, user, url);

        // Absensi, Nilai, Rapor monitoring
        if (subPath.startsWith('absensi')) {
          return handleAdminAbsensi(request, env, user, url);
        }
        if (subPath.startsWith('nilai')) {
          return handleAdminNilai(request, env, user, url);
        }
        if (subPath.startsWith('rapor')) {
          return handleAdminRapor(request, env, user, url);
        }

        // Dauroh (Admin)
        if (subPath === 'dauroh' || subPath.startsWith('dauroh/')) {
          return handleAdminDauroh(request, env, user, pathParts, url);
        }
      }

      // Wakil Kurikulum routes
      if (pathParts[0] === 'api' && pathParts[1] === 'wakil-kurikulum') {
        if (user.role !== 'wakil_kurikulum') return error('Forbidden', 403);

        const subPath = pathParts.slice(2).join('/');

        if (subPath === 'dashboard') return handleDashboardWK(env);
        if (subPath.startsWith('kesiapan') || subPath.startsWith('jp-slots') || subPath.startsWith('referensi') || subPath.startsWith('jadwal') || subPath.startsWith('jadwal-per-kelas') || subPath.startsWith('beban') || subPath.startsWith('jadwal-guru') || subPath.startsWith('jadwal-kelas') || subPath.startsWith('wali-kelas') || subPath.startsWith('kelas-gabungan') || subPath.startsWith('kegiatan-tetap')) {
          return handlePenjadwalan(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('bobot-nilai') || subPath.startsWith('monitoring-nilai') || subPath.startsWith('status-pengumpulan')) {
          return handleNilaiWK(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('absensi')) {
          return handleAbsensiWK(request, env, url);
        }
        if (subPath.startsWith('dauroh')) {
          return handleDaurohWK(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('kenaikan-kelas') || subPath.startsWith('alumni')) {
          return handleKenaikanKelas(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('laporan')) {
          return handleLaporanWK(request, env, user, pathParts, url);
        }
      }

      // Guru Mapel / Wali Kelas routes
      if (pathParts[0] === 'api' && pathParts[1] === 'guru') {
        if (user.role !== 'guru_mapel_wali_kelas') return error('Forbidden', 403);

        const subPath = pathParts.slice(2).join('/');

        if (subPath === 'dashboard') return handleDashboardGuru(env, user);
        if (subPath.startsWith('absensi')) {
          return handleAbsensiGuru(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('nilai')) {
          return handleNilaiGuru(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('rapor')) {
          return handleRaporGuru(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('pengaduan')) {
          return handlePengaduan(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('materi')) {
          return handleMateriGuru(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('data-siswa') || subPath.startsWith('rekap-absensi') || subPath.startsWith('rekap-nilai') || subPath.startsWith('catatan-wali')) {
          return handleWaliKelas(request, env, user, pathParts, url);
        }
        if (subPath === 'jadwal' && request.method === 'GET') {
          return handleJadwalGuru(env, user);
        }
        if (subPath === 'profil' && request.method === 'GET') {
          return handleProfilGuru(env, user);
        }
      }

      // Kepala Sekolah routes
      if (pathParts[0] === 'api' && pathParts[1] === 'kepala-sekolah') {
        if (user.role !== 'kepala_sekolah') return error('Forbidden', 403);

        const subPath = pathParts.slice(2).join('/');

        if (subPath === 'dashboard') return handleDashboardKS(env);
        if (subPath === 'jadwal') return handleJadwalKS(request, env, url);
        if (subPath === 'absensi') return handleAbsensiKS(request, env, url);
        if (subPath === 'nilai') return handleNilaiKS(request, env, url);
        if (subPath === 'dauroh/nilai' || subPath === 'dauroh/filters') return handleDaurohKS(request, env, user, pathParts, url);
        if (subPath === 'rapor') return handleRaporKS(request, env, url);
        if (subPath === 'bk') return handleBKKS(request, env, url);
        if (subPath === 'laporan') return handleLaporanKS(request, env, url);
      }

      // Musyrifah routes
      if (pathParts[0] === 'api' && pathParts[1] === 'musyrifah') {
        if (user.role !== 'musyrifah') return error('Forbidden: musyrifah only', 403);
        return handleMusyrifahRoutes(request, env, user, pathParts, url);
      }

      // Guru BK routes
      if (pathParts[0] === 'api' && pathParts[1] === 'guru-bk') {
        if (user.role !== 'guru_bk') return error('Forbidden', 403);

        const subPath = pathParts.slice(2).join('/');

        if (subPath.startsWith('pengaduan')) {
          return handlePengaduanBK(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('jadwal-konseling') || subPath.startsWith('konseling') || subPath.startsWith('bakat-minat')) {
          return handleKonselingBK(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('monitoring')) {
          return handleMonitoringBK(request, env, url);
        }
        if (subPath.startsWith('statistik') || subPath.startsWith('bulanan') || subPath.startsWith('rekap-kasus') || subPath.startsWith('laporan/')) {
          return handleLaporanBK(request, env, user, pathParts, url);
        }
      }

      // Siswa routes
      if (pathParts[0] === 'api' && pathParts[1] === 'siswa') {
        if (user.role !== 'siswa') return error('Forbidden: siswa only', 403);
        return handleSiswaRoutes(request, env, user, pathParts, url);
      }

      // Shared referensi endpoint (any role)
      if (path === '/api/referensi' && request.method === 'GET') {
        return handleReferensi(env);
      }

      return error('Not Found', 404);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Internal Server Error';
      return error(msg, 500);
    } finally {
      // CORS headers sudah di-handle oleh error()/success()/json()
    }
  },
};

async function handleLogin(request: Request, env: Env): Promise<Response> {
  let body: { username?: string; credential?: string; password?: string };
  try {
    body = await request.json();
  } catch {
    return error('Invalid JSON body', 400);
  }

  const credential = body.username || body.credential;
  const { password } = body;
  if (!credential || !password) {
    return error('Username/NIS and password are required', 400);
  }

  // Brute force check
  const bfCheck = await bruteForceCheck(credential, request, env);
  if (bfCheck) return bfCheck;

  // 1. Coba cari di users WHERE username = ? (admin/guru/WK/BK/KS)
  let result = await env.DB.prepare(
    'SELECT id, username, password_hash, role, guru_id, is_active FROM users WHERE username = ?'
  ).bind(credential).first<{
    id: number; username: string; password_hash: string; role: Role;
    guru_id: number | null; siswa_id: null; is_active: number;
  }>();

  let siswaInfo: { siswa_id: number; nama: string; nis: string; kelas_id: number | null; kelas_nama: string | null } | null = null;

  // 2. Jika tidak ditemukan, coba cari sebagai NIS siswa
  if (!result) {
    const siswaResult = await env.DB.prepare(
      `SELECT u.id, u.username, u.password_hash, u.role, u.siswa_id, u.is_active,
              s.nama as siswa_nama, s.nis, s.kelas_id, k.nama as kelas_nama
       FROM users u
       JOIN siswa s ON u.siswa_id = s.id
       LEFT JOIN kelas k ON s.kelas_id = k.id
       WHERE s.nis = ? AND u.role = 'siswa' AND u.is_active = 1`
    ).bind(credential).first<{
      id: number; username: string; password_hash: string; role: Role;
      siswa_id: number; is_active: number; siswa_nama: string; nis: string;
      kelas_id: number | null; kelas_nama: string | null;
    }>();

    if (siswaResult) {
      result = {
        id: siswaResult.id,
        username: siswaResult.username,
        password_hash: siswaResult.password_hash,
        role: siswaResult.role,
        guru_id: null,
        siswa_id: null,
        is_active: siswaResult.is_active,
      };
      siswaInfo = {
        siswa_id: siswaResult.siswa_id,
        nama: siswaResult.siswa_nama,
        nis: siswaResult.nis,
        kelas_id: siswaResult.kelas_id,
        kelas_nama: siswaResult.kelas_nama,
      };
    }
  }

  if (!result) {
    await bruteForceRecordFailure(credential, request, env);
    return error('Username atau password salah', 401);
  }

  if (!result.is_active) return error('Account is disabled', 403);

  const passwordMatch = await bcrypt.compare(password, result.password_hash);
  if (!passwordMatch) {
    await bruteForceRecordFailure(credential, request, env);
    return error('Username atau password salah', 401);
  }

  // Login berhasil
  await bruteForceRecordSuccess(credential, env);

  const isSiswa = result.role === 'siswa';

  // Ambil nama guru dari table guru jika ada guru_id
  let guruNama: string | null = null;
  if (result.guru_id) {
    const guruData = await env.DB.prepare('SELECT nama FROM guru WHERE id = ?').bind(result.guru_id).first<{ nama: string }>();
    guruNama = guruData?.nama ?? null;
  }

  const userPayload = {
    sub: result.id,
    username: result.username,
    role: result.role as Role,
    guru_id: result.guru_id,
    siswa_id: siswaInfo?.siswa_id ?? null,
  };
  const token = await generateToken(userPayload, env);
  const refreshToken = await generateRefreshToken(result.id, env);

  // Buat session baru (device limiting: max 2 perangkat)
  const userAgent = request.headers.get('User-Agent') || 'unknown';
  const tokenHash = await hashToken(token);
  await createSession(result.id, tokenHash, userAgent, env);

  await env.DB.prepare("UPDATE users SET last_login_at = datetime('now') WHERE id = ?").bind(result.id).run();

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'login', 'auth', ?, ?)"
  ).bind(result.id, `Login ${isSiswa ? 'siswa' : 'user'} ${result.username}`, ip).run();

  const userData: Record<string, unknown> = {
    id: result.id,
    username: result.username,
    role: result.role,
    guru_id: result.guru_id,
    nama: guruNama,
  };

  if (isSiswa && siswaInfo) {
    userData.siswa_id = siswaInfo.siswa_id;
    userData.nama = siswaInfo.nama;
    userData.nis = siswaInfo.nis;
    userData.kelas_id = siswaInfo.kelas_id;
    userData.kelas_nama = siswaInfo.kelas_nama;
  }

  return success({ token, refresh_token: refreshToken, user: userData });
}

async function handleLoginSiswa(request: Request, env: Env): Promise<Response> {
  let body: { nis?: string; password?: string };
  try {
    body = await request.json();
  } catch {
    return error('Invalid JSON body', 400);
  }

  const { nis, password } = body;
  if (!nis || !password) {
    return error('NIS dan password wajib diisi', 400);
  }

  // Brute force check
  const bfCheck = await bruteForceCheck(`siswa:${nis}`, request, env);
  if (bfCheck) return bfCheck;

  // Cari user yang terhubung ke siswa via siswa_id
  const result = await env.DB.prepare(
    `SELECT u.id, u.username, u.password_hash, u.role, u.siswa_id, u.is_active,
            s.nama as siswa_nama, s.nis, s.kelas_id, k.nama as kelas_nama
     FROM users u
     JOIN siswa s ON u.siswa_id = s.id
     LEFT JOIN kelas k ON s.kelas_id = k.id
     WHERE s.nis = ? AND u.role = 'siswa' AND u.is_active = 1`
  ).bind(nis).first<{
    id: number; username: string; password_hash: string; role: Role;
    siswa_id: number; is_active: number; siswa_nama: string; nis: string;
    kelas_id: number | null; kelas_nama: string | null;
  }>();

  if (!result) {
    await bruteForceRecordFailure(`siswa:${nis}`, request, env);
    return error('NIS tidak terdaftar atau akun belum dibuat', 401);
  }

  const passwordMatch = await bcrypt.compare(password, result.password_hash);
  if (!passwordMatch) {
    await bruteForceRecordFailure(`siswa:${nis}`, request, env);
    return error('Password salah', 401);
  }

  // Login berhasil
  await bruteForceRecordSuccess(`siswa:${nis}`, env);

  const userPayload = {
    sub: result.id,
    username: result.username,
    role: 'siswa' as Role,
    guru_id: null,
    siswa_id: result.siswa_id,
  };
  const token = await generateToken(userPayload, env);
  const refreshToken = await generateRefreshToken(result.id, env);

  // Buat session baru (device limiting: max 2 perangkat)
  const userAgent = request.headers.get('User-Agent') || 'unknown';
  const tokenHash = await hashToken(token);
  await createSession(result.id, tokenHash, userAgent, env);

  await env.DB.prepare("UPDATE users SET last_login_at = datetime('now') WHERE id = ?").bind(result.id).run();

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'login', 'auth', ?, ?)"
  ).bind(result.id, `Login siswa ${result.siswa_nama} (NIS: ${nis})`, ip).run();

  return success({
    token,
    refresh_token: refreshToken,
    user: {
      id: result.id,
      username: result.username,
      role: 'siswa',
      siswa_id: result.siswa_id,
      nama: result.siswa_nama,
      nis: result.nis,
      kelas_id: result.kelas_id,
      kelas_nama: result.kelas_nama,
    },
  });
}

async function handleMe(user: { sub: number; username: string; role: string; guru_id: number | null; siswa_id: number | null }, env: Env): Promise<Response> {
  let nama: string | null = null;

  if (user.role === 'siswa' && user.siswa_id) {
    const siswa = await env.DB.prepare('SELECT nama FROM siswa WHERE id = ?').bind(user.siswa_id).first<{ nama: string }>();
    nama = siswa?.nama ?? null;
  } else if (user.guru_id) {
    const guru = await env.DB.prepare('SELECT nama FROM guru WHERE id = ?').bind(user.guru_id).first<{ nama: string }>();
    nama = guru?.nama ?? null;
  }

  return success({
    id: user.sub,
    username: user.username,
    role: user.role,
    guru_id: user.guru_id,
    siswa_id: user.siswa_id,
    nama,
  });
}

async function handleRefresh(request: Request, env: Env): Promise<Response> {
  let body: { refresh_token?: string; username?: string; token?: string };
  try {
    body = await request.json();
  } catch {
    return error('Invalid JSON body', 400);
  }

  const { refresh_token, username, token: oldToken } = body;
  if (!refresh_token) return error('refresh_token is required', 400);

  // Brute force check untuk refresh token (pakai username jika ada)
  if (username) {
    const bfCheck = await bruteForceCheck(username, request, env);
    if (bfCheck) return bfCheck;
  }

  const payload = await verifyRefreshToken(refresh_token, env);
  if (!payload) return error('Invalid or expired refresh token', 401);

  const user = await env.DB.prepare(
    'SELECT id, username, role, guru_id, siswa_id, is_active FROM users WHERE id = ?'
  ).bind(payload.sub).first<{ id: number; username: string; role: Role; guru_id: number | null; siswa_id: number | null; is_active: number }>();

  if (!user || !user.is_active) return error('User not found or disabled', 401);

  const userPayload = { sub: user.id, username: user.username, role: user.role, guru_id: user.guru_id, siswa_id: user.siswa_id ?? null };
  const newToken = await generateToken(userPayload, env);
  const newRefreshToken = await generateRefreshToken(user.id, env);

  // Revoke session lama (berdasarkan token yang dikirim frontend)
  if (oldToken) {
    const oldTokenHash = await hashToken(oldToken);
    await env.DB.prepare(
      "UPDATE sessions SET is_active = 0, revoked_at = datetime('now') WHERE token_hash = ? AND user_id = ? AND is_active = 1"
    ).bind(oldTokenHash, user.id).run();
  }

  // Buat session baru untuk token baru
  const userAgent = request.headers.get('User-Agent') || 'unknown';
  const newTokenHash = await hashToken(newToken);
  await createSession(user.id, newTokenHash, userAgent, env);

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'refresh_token', 'auth', ?, ?)"
  ).bind(user.id, `Token refresh untuk user ${user.username}`, ip).run();

  return success({
    token: newToken,
    refresh_token: newRefreshToken,
    user: { id: user.id, username: user.username, role: user.role, guru_id: user.guru_id, siswa_id: user.siswa_id ?? null },
  });
}

async function handleLogout(request: Request, env: Env, user: UserPayload): Promise<Response> {
  let body: { token?: string };
  try {
    body = await request.json();
  } catch {
    body = {};
  }

  // Revoke session berdasarkan token jika dikirim
  if (body.token) {
    const tokenHash = await hashToken(body.token);
    await env.DB.prepare(
      "UPDATE sessions SET is_active = 0, revoked_at = datetime('now') WHERE token_hash = ? AND user_id = ? AND is_active = 1"
    ).bind(tokenHash, user.sub).run();
  } else {
    // Revoke semua session aktif user ini
    await env.DB.prepare(
      "UPDATE sessions SET is_active = 0, revoked_at = datetime('now') WHERE user_id = ? AND is_active = 1"
    ).bind(user.sub).run();
  }

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'logout', 'auth', ?, ?)"
  ).bind(user.sub, `Logout user ${user.username}`, ip).run();

  return success({ message: 'Logged out successfully' });
}

async function handleJadwalGuru(env: Env, user: UserPayload): Promise<Response> {
  const guruId = user.guru_id;
  if (!guruId) return success([]);
  const semester = await env.DB.prepare("SELECT id FROM semester WHERE is_aktif = 1 LIMIT 1").first<{ id: number }>();
  if (!semester) return success([]);
  const rows = await env.DB.prepare(`
    SELECT jp.*, mp.nama as mapel_nama, k.nama as kelas_nama, r.nama as ruangan_nama
    FROM jadwal_pelajaran jp
    LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
    LEFT JOIN kelas k ON jp.kelas_id = k.id
    LEFT JOIN ruangan r ON jp.ruangan_id = r.id
    WHERE jp.guru_id = ? AND jp.semester_id = ? AND jp.status_validasi = 'tervalidasi'
    ORDER BY CASE jp.hari
      WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
      WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
      ELSE 7 END, jp.jam_mulai
  `).bind(guruId, semester.id).all();
  return success(rows.results);
}

async function handleProfilGuru(env: Env, user: UserPayload): Promise<Response> {
  const guruId = user.guru_id;
  if (!guruId) return success(null);

  const profil = await env.DB.prepare(
    `SELECT id, nip, nama, jenis_kelamin, tempat_lahir, tanggal_lahir, alamat, no_hp, email, status,
            jabatan, status_aktif, created_at
     FROM guru WHERE id = ?`
  ).bind(guruId).first();

  return success(profil || null);
}

async function handleDashboardGuru(env: Env, user: UserPayload): Promise<Response> {
  const guruId = user.guru_id;
  if (!guruId) return success({ jadwal_hari_ini: 0, total_absensi: 0, total_nilai: 0, pengaduan_aktif: 0 });

  const [jadwal, absensi, nilai, pengaduan] = await Promise.all([
    env.DB.prepare(
      `SELECT COUNT(*) as total FROM jadwal_pelajaran WHERE guru_id = ? AND hari = CASE CAST(strftime('%w', 'now') AS INTEGER) WHEN 1 THEN 'Senin' WHEN 2 THEN 'Selasa' WHEN 3 THEN 'Rabu' WHEN 4 THEN 'Kamis' WHEN 5 THEN 'Jumat' WHEN 6 THEN 'Sabtu' ELSE '' END`
    ).bind(guruId).first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM absensi_siswa WHERE diinput_oleh = ?').bind(guruId).first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM nilai WHERE diinput_oleh = ?').bind(guruId).first<{ total: number }>(),
    env.DB.prepare("SELECT COUNT(*) as total FROM pengaduan WHERE dilaporkan_oleh = ? AND status = 'baru'").bind(guruId).first<{ total: number }>(),
  ]);

  return success({
    jadwal_hari_ini: jadwal?.total || 0,
    total_absensi: absensi?.total || 0,
    total_nilai: nilai?.total || 0,
    pengaduan_aktif: pengaduan?.total || 0,
  });
}

async function handleReferensi(env: Env): Promise<Response> {
  const [kelas, mataPelajaran, semester, siswa, tahunAjaran, tingkat, semesterAll] = await Promise.all([
    env.DB.prepare('SELECT id, nama FROM kelas ORDER BY nama').all(),
    env.DB.prepare('SELECT id, nama, kode FROM mata_pelajaran ORDER BY nama').all(),
    env.DB.prepare('SELECT id, nama, tahun_ajaran_id FROM semester WHERE is_aktif = 1 ORDER BY tahun_ajaran_id DESC, nama').all(),
    env.DB.prepare("SELECT id, nis, nama, kelas_id FROM siswa WHERE status = 'aktif' ORDER BY nama").all(),
    env.DB.prepare('SELECT id, nama FROM tahun_ajaran ORDER BY nama DESC').all(),
    env.DB.prepare('SELECT id, nama FROM tingkat ORDER BY id').all(),
    env.DB.prepare("SELECT id, nama, tahun_ajaran_id FROM semester ORDER BY tahun_ajaran_id DESC, id").all(),
  ]);

  return success({
    kelas: kelas.results,
    mata_pelajaran: mataPelajaran.results,
    semester: semester.results,
    siswa: siswa.results,
    tahun_ajaran: tahunAjaran.results,
    tingkat: tingkat.results,
    semester_all: semesterAll.results,
  });
}

async function handleDashboardWK(env: Env): Promise<Response> {
  const [jadwalCount, nilaiCount, draftCount] = await Promise.all([
    env.DB.prepare('SELECT COUNT(*) as total FROM jadwal_pelajaran').first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM nilai').first<{ total: number }>(),
    env.DB.prepare("SELECT COUNT(*) as total FROM nilai WHERE status_validasi = 'draft'").first<{ total: number }>(),
  ]);

  return success({
    jadwal: jadwalCount?.total || 0,
    total_nilai: nilaiCount?.total || 0,
    nilai_belum_divalidasi: draftCount?.total || 0,
  });
}

// ═══════════════════════════════════════════════════════════════
//  QR SCAN ABSENSI GURU (shared untuk guru, WK, KS)
//  Window: masuk 06:30-10:00 WIB, keluar 11:00-15:00 WIB
//  (dapat disesuaikan via env JAM_MASUK_*/JAM_KELUAR_*)
// ═══════════════════════════════════════════════════════════════
const WIB_MS = 7 * 60 * 60 * 1000;

async function handleScanAbsensi(request: Request, env: Env, user: UserPayload): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  // Hanya role tertentu yang boleh scan
  const allowedRoles = ['guru_mapel_wali_kelas', 'wakil_kurikulum', 'kepala_sekolah'];
  if (!allowedRoles.includes(user.role)) {
    return error('Role Anda tidak memiliki akses absensi', 403);
  }

  // Validasi token QR absensi (wajib dikirim dari client)
  const body = await request.json().catch(() => null) as { token?: string } | null;
  const expectedToken = env.QR_ABSENSI_TOKEN || 'PPI_ABSENSI_QR_2026';
  if (!body?.token || body.token !== expectedToken) {
    return error('QR Code tidak valid', 400);
  }

  // Guru harus punya guru_id
  if (!user.guru_id) {
    return error('Data guru tidak ditemukan untuk akun ini', 400);
  }

  // Waktu selalu dalam WIB (UTC+7)
  const wibNow = new Date(Date.now() + WIB_MS);
  const today = wibNow.toISOString().split('T')[0];       // YYYY-MM-DD (WIB)
  const currentTime = wibNow.toISOString().slice(11, 19); // HH:MM:SS (WIB)

  // Window jam absensi (default: masuk 06:30-10:00, keluar 11:00-15:00 WIB)
  const masukMulai = env.JAM_MASUK_MULAI || '06:30:00';
  const masukSelesai = env.JAM_MASUK_SELESAI || '10:00:00';
  const keluarMulai = env.JAM_KELUAR_MULAI || '11:00:00';
  const keluarSelesai = env.JAM_KELUAR_SELESAI || '15:00:00';

  const inJamMasuk = currentTime >= masukMulai && currentTime <= masukSelesai;
  const inJamKeluar = currentTime >= keluarMulai && currentTime <= keluarSelesai;

  // Cek apakah sudah ada absensi hari ini
  const existing = await env.DB.prepare(
    'SELECT id, jam_masuk, jam_keluar FROM absensi_guru WHERE guru_id = ? AND tanggal = ?'
  ).bind(user.guru_id, today).first<{ id: number; jam_masuk: string | null; jam_keluar: string | null }>();

  // Di luar window jam absensi
  if (!inJamMasuk && !inJamKeluar) {
    return error(
      `Di luar jam absensi. Jam masuk ${masukMulai.slice(0, 5)}–${masukSelesai.slice(0, 5)}, jam keluar ${keluarMulai.slice(0, 5)}–${keluarSelesai.slice(0, 5)} WIB`,
      400
    );
  }

  if (inJamMasuk) {
    if (!existing) {
      // Scan masuk → Jam Masuk
      await env.DB.prepare(
        'INSERT INTO absensi_guru (guru_id, tanggal, jam_masuk, status) VALUES (?, ?, ?, ?)'
      ).bind(user.guru_id, today, currentTime, 'hadir').run();

      // Log aktivitas
      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'scan_masuk', 'absensi_guru', ?, ?)"
      ).bind(user.sub, `Scan QR masuk - ${user.username}`, ip).run();

      return success({
        action: 'jam_masuk',
        time: currentTime,
        message: `Absensi masuk tercatat pukul ${currentTime} WIB`,
      });
    }
    if (existing.jam_masuk && !existing.jam_keluar) {
      return error(`Jam masuk sudah tercatat. Jam keluar dibuka pukul ${keluarMulai.slice(0, 5)} WIB.`, 400);
    }
    return error('Anda sudah melakukan absensi masuk dan keluar hari ini', 400);
  }

  // inJamKeluar
  if (!existing || !existing.jam_masuk) {
    return error('Belum ada absen masuk hari ini', 400);
  }
  if (existing.jam_masuk && !existing.jam_keluar) {
    // Scan keluar → Jam Keluar
    await env.DB.prepare(
      'UPDATE absensi_guru SET jam_keluar = ? WHERE id = ?'
    ).bind(currentTime, existing.id).run();

    // Log aktivitas
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'scan_keluar', 'absensi_guru', ?, ?)"
    ).bind(user.sub, `Scan QR keluar - ${user.username}`, ip).run();

    return success({
      action: 'jam_keluar',
      time: currentTime,
      message: `Absensi keluar tercatat pukul ${currentTime} WIB`,
    });
  }
  return error('Anda sudah melakukan absensi masuk dan keluar hari ini', 400);
}
