import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../loans/loans_screen.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../clients/clients_screen.dart';
import '../payments/payments_screen.dart';
import '../cash/cash_screen.dart';
import '../collectors/collectors_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  int _selectedIndex = 0;

  final List<_ModuleItem> _modules = const [
    _ModuleItem('Inicio', Icons.dashboard_rounded),
    _ModuleItem('Clientes', Icons.people_alt_outlined),
    _ModuleItem('Préstamos', Icons.account_balance_outlined),
    _ModuleItem('Cobros', Icons.payments_outlined),
    _ModuleItem('Caja diaria', Icons.point_of_sale_outlined),
    _ModuleItem('Cobradores', Icons.route_outlined),
    _ModuleItem('Reportes', Icons.bar_chart_rounded),
    _ModuleItem('Configuración', Icons.settings_outlined),
  ];

  Future<void> _logout() async {
    try {
      await _auth.logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo cerrar la sesión.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 950;
    final user = _auth.currentUser;
    final userName = user?.userMetadata?['full_name']?.toString() ?? 'Administrador';
    final email = user?.email ?? '';

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            _Sidebar(
              modules: _modules,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
              userName: userName,
              email: email,
              onLogout: _logout,
            ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  userName: userName,
                  email: email,
                  onLogout: _logout,
                  desktop: isDesktop,
                ),
                Expanded(
                  child: _selectedIndex == 0
                      ? _Dashboard(
                          userName: userName,
                          onModuleSelected: (index) => setState(() => _selectedIndex = index),
                        )
                      : _selectedIndex == 1
                          ? const ClientsScreen()
                          : _selectedIndex == 2
                              ? const LoansScreen()
                              : _selectedIndex == 3
                                  ? const PaymentsScreen()
                                  : _selectedIndex == 4
                                      ? const CashScreen()
                                      : _selectedIndex == 5
                                          ? const CollectorsScreen()
                                          : _selectedIndex == 6
                                              ? const ReportsScreen()
                                              : _selectedIndex == 7
                                                  ? const SettingsScreen()
                                                  : _ModulePlaceholder(module: _modules[_selectedIndex]),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
              indicatorColor: const Color(0xFFEAF1FF),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Inicio'),
                NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Clientes'),
                NavigationDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance_rounded), label: 'Préstamos'),
                NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments_rounded), label: 'Cobros'),
                NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale_rounded), label: 'Caja'),
              ],
            ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<_ModuleItem> modules;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String userName;
  final String email;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.modules,
    required this.selectedIndex,
    required this.onSelected,
    required this.userName,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 255,
      color: const Color(0xFF0F172A), // Sidebar siempre oscuro
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(23, 28, 20, 35),
            child: Row(
              children: [
                Container(
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: [zBlue, zCyan]),
                  ),
                  child: const Center(
                    child: Text('Z', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 27)),
                  ),
                ),
                const SizedBox(width: 11),
                Text(
                  'Z FINANCES',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.7),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 24, bottom: 13),
            child: Text('MENÚ PRINCIPAL', style: TextStyle(color: Color(0xFF71809A), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final item = modules[index];
                final selected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: InkWell(
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: selected ? zBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 19, color: selected ? Colors.white : const Color(0xFF9BA9BF)),
                          const SizedBox(width: 13),
                          Text(
                            item.name,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFFB7C2D3),
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const CircleAvatar(radius: 18, backgroundColor: Color(0xFF284A80), child: Icon(Icons.person, color: Colors.white, size: 19)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8F9EB4), fontSize: 10)),
                    ],
                  ),
                ),
                IconButton(onPressed: onLogout, tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout_rounded, color: Color(0xFF9BA9BF), size: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String userName;
  final String email;
  final VoidCallback onLogout;
  final bool desktop;

  const _TopBar({required this.userName, required this.email, required this.onLogout, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFEBEFF5);

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 27),
      decoration: BoxDecoration(color: bgColor, border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        children: [
          if (!desktop) ...[
            Container(
              width: 35, height: 35,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [zBlue, zCyan])),
              child: const Center(child: Text('Z', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 10),
            Text('Z FINANCES', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : zNavy, letterSpacing: 0.6)),
          ] else ...[
            Text('Panel de control', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? Colors.white : zText)),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5FB), borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: zBlue, size: 19),
                if (desktop) ...[
                  const SizedBox(width: 8),
                  Text(userName, style: TextStyle(color: isDark ? Colors.white : zText, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          if (!desktop) ...[
            const SizedBox(width: 7),
            IconButton(tooltip: 'Cerrar sesión', onPressed: onLogout, icon: Icon(Icons.logout_rounded, color: isDark ? Colors.white70 : zMuted)),
          ],
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final String userName;
  final ValueChanged<int> onModuleSelected;

  const _Dashboard({required this.userName, required this.onModuleSelected});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 950;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : zText;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE8EDF4);

    return SingleChildScrollView(
      padding: EdgeInsets.all(desktop ? 32 : 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hola, ${userName.split(' ').first}', style: GoogleFonts.inter(color: textColor, fontSize: desktop ? 29 : 25, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 7),
          Text('Bienvenido a tu centro de administración financiera.', style: TextStyle(color: isDark ? Colors.grey.shade400 : zMuted, fontSize: 13)),
          const SizedBox(height: 27),
          _WelcomeCard(),
          const SizedBox(height: 31),
          Text('Tu espacio de trabajo', style: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text('Accede a las herramientas principales de Z Finances.', style: TextStyle(color: isDark ? Colors.grey.shade400 : zMuted, fontSize: 12)),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: desktop ? 3 : (width >= 600 ? 2 : 2),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 155,
            ),
            itemBuilder: (context, index) {
              final items = [
                _ModuleItem('Clientes', Icons.people_alt_outlined),
                _ModuleItem('Préstamos', Icons.account_balance_outlined),
                _ModuleItem('Cobros', Icons.payments_outlined),
                _ModuleItem('Caja diaria', Icons.point_of_sale_outlined),
                _ModuleItem('Cobradores', Icons.route_outlined),
                _ModuleItem('Reportes', Icons.bar_chart_rounded),
              ];

              return _ModuleCard(
                item: items[index],
                onTap: () => onModuleSelected(index + 1),
              );
            },
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(17), border: Border.all(color: borderColor)),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: zBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Tus módulos se conectarán progresivamente a la base de datos para mostrar información real de tu empresa.', style: TextStyle(color: isDark ? Colors.grey.shade400 : zMuted, fontSize: 12, height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173B78), Color(0xFF2563EB), Color(0xFF1679B9)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -35,
            child: Icon(Icons.account_balance_wallet_rounded, size: 145, color: Colors.white.withOpacity(0.09)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(30)),
                child: const Text('Z FINANCES', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 18),
              const Text('Organiza tu negocio.\nControla tus finanzas.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 11),
              const Text('Todo lo que necesitas para gestionar tu operación desde un solo lugar.', style: TextStyle(color: Color(0xFFD9E8FF), fontSize: 12, height: 1.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _ModuleItem item;
  final VoidCallback onTap;

  const _ModuleCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE8EDF4);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: borderColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: isDark ? Colors.blue.withOpacity(0.2) : const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(13)),
                child: Icon(item.icon, color: zBlue, size: 22),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white : zText)),
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 17, color: isDark ? Colors.grey : zMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModulePlaceholder extends StatelessWidget {
  final _ModuleItem module;

  const _ModulePlaceholder({required this.module});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82, height: 82,
              decoration: BoxDecoration(color: isDark ? Colors.blue.withOpacity(0.2) : const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(24)),
              child: Icon(module.icon, color: zBlue, size: 39),
            ),
            const SizedBox(height: 22),
            Text(module.name, style: TextStyle(color: isDark ? Colors.white : zText, fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            Text('Este módulo está preparado para su integración con Supabase.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : zMuted, fontSize: 13, height: 1.5)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('Módulo en desarrollo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleItem {
  final String name;
  final IconData icon;

  const _ModuleItem(this.name, this.icon);
}