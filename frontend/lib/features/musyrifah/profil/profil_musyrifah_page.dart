import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/musyrifah_service.dart';

class ProfilMusyrifahPage extends StatefulWidget {
  const ProfilMusyrifahPage({super.key});

  @override
  State<ProfilMusyrifahPage> createState() => _ProfilMusyrifahPageState();
}

class _ProfilMusyrifahPageState extends State<ProfilMusyrifahPage> {
  Map<String, dynamic>? _profil;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MusyrifahService.getProfil();
      if (mounted) {
        setState(() {
          _profil = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
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
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text('Profil Musyrifah',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _profil == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _error ?? 'Gagal memuat profil',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.error),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildAvatar(),
                          const SizedBox(height: 24),
                          _buildInfoCard(),
                          const SizedBox(height: 24),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final nama = _profil?['nama']?.toString() ?? 'M';
    return CircleAvatar(
      radius: 50,
      backgroundColor: AppTheme.primaryLight,
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : 'M',
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoTile(Icons.person_outline, 'Nama', _profil?['nama']?.toString() ?? '-'),
          _buildInfoTile(Icons.badge_outlined, 'NIPMUS', _profil?['nipmus']?.toString() ?? '-'),
          _buildInfoTile(Icons.wc_outlined, 'Jenis Kelamin', _profil?['jenis_kelamin']?.toString() == 'L' ? 'Laki-laki' : 'Perempuan'),
          _buildInfoTile(Icons.school_outlined, 'Status Pendidikan', _profil?['status_pendidikan']?.toString() == 'selesai' ? 'Selesai (Sarjana)' : 'Mahasiswa'),
          if (_profil?['gelar']?.toString().isNotEmpty == true)
            _buildInfoTile(Icons.emoji_events_outlined, 'Gelar', _profil!['gelar'].toString()),
          _buildInfoTile(Icons.account_circle_outlined, 'Username', _profil?['username']?.toString() ?? '-'),
          _buildInfoTile(
            Icons.toggle_on_outlined,
            'Status',
            _profil?['is_aktif'] == 1 ? 'Aktif' : 'Tidak Aktif',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.grey500),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.grey500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
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
    );
  }
}
