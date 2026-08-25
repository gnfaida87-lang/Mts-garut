import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../services/guru_service.dart';

class ProfilPageGuru extends StatefulWidget {
  const ProfilPageGuru({super.key});

  @override
  State<ProfilPageGuru> createState() => _ProfilPageGuruState();
}

class _ProfilPageGuruState extends State<ProfilPageGuru> {
  Map<String, dynamic>? _profil;
  bool _loading = true;
  bool _isWaliKelas = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/guru/profil');
      _profil = res['data'] as Map<String, dynamic>?;
    } catch (_) {}
    try {
      final wali = await GuruService.cekWaliKelas();
      _isWaliKelas = wali['is_wali_kelas'] == true;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String get _jabatanDisplay {
    final raw = _profil?['jabatan']?.toString() ?? '';
    if (raw.trim().isNotEmpty) return UserModel.jabatanGuru(jabatan: raw);
    return UserModel.jabatanGuru(isWaliKelas: _isWaliKelas);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yakin ingin logout?'),
        content: const Text('Anda akan keluar dari sistem.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = _profil?['nama']?.toString() ?? user?.username ?? 'Asatidz';
    final jabatanDisplay = _jabatanDisplay;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),

        // ── Avatar & Nama ──
        Center(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFFF5EBE0),
                child: Icon(Icons.person, color: Color(0xFF9C6644), size: 48),
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C6644).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(jabatanDisplay, style: const TextStyle(color: Color(0xFF9C6644), fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 16),

              // ── Tombol Keluar ──
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Keluar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Data Diri ──
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_profil != null)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Diri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _infoRow('NIP', _profil!['nip']?.toString()),
                  _infoRow('Nama Lengkap', _profil!['nama']?.toString()),
                  _infoRow('Jenis Kelamin', _profil!['jenis_kelamin']?.toString()),
                  _infoRow('Tempat Lahir', _profil!['tempat_lahir']?.toString()),
                  _infoRow('Tanggal Lahir', _profil!['tanggal_lahir']?.toString()),
                  _infoRow('Alamat', _profil!['alamat']?.toString()),
                  _infoRow('No. HP', _profil!['no_hp']?.toString()),
                  _infoRow('Email', _profil!['email']?.toString()),
                  _infoRow('Jabatan', jabatanDisplay),
                  _infoRow('Status', _profil!['status_aktif'] == 1 ? 'Aktif' : 'Tidak Aktif'),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Data profil asatidz', style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text('Username: ${user?.username ?? '-'}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}
