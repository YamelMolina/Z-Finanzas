import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import 'dashboard_content.dart';
import '../clients/clients_screen.dart';
import '../loans/loans_screen.dart';
import '../payments/payments_screen.dart';
import '../cash/cash_screen.dart';
import '../collectors/collectors_screen.dart'; // <-- NUEVO
import '../reports/reports_screen.dart'; // <-- NUEVO
import '../settings/settings_screen.dart'; // <-- NUEVO

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _reportService = ReportService();
  int _selectedIndex = 0;
  int _overdueCount = 0;

  final List<Widget> _pages = [
    const DashboardContent(userName: 'Administrador'),
    const ClientsScreen(),
    const LoansScreen(),
    const PaymentsScreen(),
    const CashScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final stats = await _reportService.getDashboardStats();
      // Simulamos que tenemos préstamos en mora
      if (mounted) setState(() => _overdueCount = stats['prestamos_activos'] ?? 0);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await _auth.logout();
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notificaciones', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.warning, color: Colors.white, size: 20)),
                title: Text('Pagos vencidos', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Tienes $_overdueCount préstamos activos. Revisa la pestaña de Cobros.', style: GoogleFonts.poppins()),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white, size: 20)),
                title: Text('Caja al día', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('No olvides cerrar tu caja al final del día.', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;
    final userName = user?.userMetadata?['full_name']?.toString() ?? 'Administrador';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : zBackground,
      drawer: _buildDrawer(isDark, userName),
      
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20, top: 12, bottom: 12),
            child: Container(
              decoration: BoxDecoration(color: zBlue, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Z', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Préstame', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : zNavy)),
              Text('ADMINISTRADOR · $userName'.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, color: zMuted, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: isDark ? Colors.white : zNavy),
              onPressed: () {
                // Navega a clientes y abre el buscador
                setState(() => _selectedIndex = 1); 
              },
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none, color: isDark ? Colors.white : zNavy),
                  onPressed: _showNotifications,
                ),
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_overdueCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: isDark ? Colors.white : zNavy),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),

      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: zBlue,
          unselectedItemColor: zMuted,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Clientes'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Préstamos'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Cobros'),
            BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_outlined), label: 'Caja'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(bool isDark, String userName) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            accountEmail: Text(_auth.currentUser?.email ?? '', style: GoogleFonts.poppins(fontSize: 12)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: zBlue,
              child: Text('Z', style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0043CE), Color(0xFF0066FF)])),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined, color: zBlue),
            title: Text('Caja', style: GoogleFonts.poppins()),
            onTap: () { Navigator.pop(context); setState(() => _selectedIndex = 4); },
          ),
          ListTile(
            leading: const Icon(Icons.route, color: zBlue),
            title: Text('Cobradores', style: GoogleFonts.poppins()),
            onTap: () { 
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorsScreen())); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_chart_outlined, color: zBlue),
            title: Text('Reportes', style: GoogleFonts.poppins()),
            onTap: () { 
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())); 
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline, color: zBlue),
            title: Text('Mi perfil', style: GoogleFonts.poppins()),
            onTap: () { 
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: zBlue),
            title: Text('Configuración', style: GoogleFonts.poppins()),
            onTap: () { 
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); 
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text('Cerrar Sesión', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () { Navigator.pop(context); _logout(); },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}