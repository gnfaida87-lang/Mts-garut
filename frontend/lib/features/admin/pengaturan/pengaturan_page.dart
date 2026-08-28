import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../services/admin_service.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/app_utils.dart';
import '../../../shared/models/user_model.dart';

part 'pengaturan_hak_akses_tab.dart';
part 'pengaturan_log_tab.dart';
part 'pengaturan_backup_restore_tab.dart';
part 'pengaturan_profil_tab.dart';
part 'pengaturan_api_keys_tab.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.security_outlined, size: 18), text: 'Hak Akses'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'Log'),
            Tab(icon: Icon(Icons.backup_outlined, size: 18), text: 'Backup'),
            Tab(icon: Icon(Icons.restore_outlined, size: 18), text: 'Restore'),
            Tab(icon: Icon(Icons.school_outlined, size: 18), text: 'Profil'),
            Tab(icon: Icon(Icons.login_outlined, size: 18), text: 'Tampilan'),
            Tab(icon: Icon(Icons.key_outlined, size: 18), text: 'API Keys'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _HakAksesTab(),
        _LogTab(),
        _BackupTab(),
        _RestoreTab(),
        _ProfilTab(),
        _TampilanLoginTab(),
        _ApiKeysTab(),
      ]),
    );
  }
}

const roleIcons = {
  'admin': Icons.shield_outlined,
  'kepala_sekolah': Icons.school_outlined,
  'wakil_kurikulum': Icons.auto_stories_outlined,
  'guru_mapel_wali_kelas': Icons.people_outlined,
  'guru_bk': Icons.psychology_outlined,
};

InputDecoration inputDecoration(String label, IconData icon) {
  return AppInputDecoration.standard(label, icon, style: InputDecorationStyle.filled, fillColor: AppTheme.grey50);
}
