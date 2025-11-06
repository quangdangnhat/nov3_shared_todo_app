import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/router/app_router.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart'; // Assicurati che questo percorso sia corretto

/// Il Drawer (menu laterale) riutilizzabile per l'applicazione.
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  /// Gestisce il logout dell'utente.
  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Ottiene la rotta corrente per evidenziare la voce di menu attiva
  String _getCurrentRoute(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return location;
  }

  /// Verifica se la rotta è attiva
  bool _isRouteActive(BuildContext context, String route) {
    final currentRoute = _getCurrentRoute(context);
    if (route == '/') {
      return currentRoute == '/' || currentRoute.startsWith('/list/');
    }
    return currentRoute == route;
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final username =
        (user?.userMetadata?['username'] as String?) ?? 'No Username';
    final email = user?.email ?? 'No Email';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.85;

    // Colori del tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: drawerWidth,
      decoration: BoxDecoration(
        // Sfondo del drawer che usa i colori del tema
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface.withOpacity(0.8), colorScheme.surface],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header personalizzato moderno
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: BoxDecoration(
              // Gradient con colori primari del tema
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.primaryContainer],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar con ombra ed effetto
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        // Ombra basata sul tema
                        color: theme.shadowColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    // Sfondo dell'avatar (chiaro)
                    backgroundColor: colorScheme.onPrimary,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        // Colore iniziale (primario)
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Username con stile moderno
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    // Colore del testo (chiaro sopra lo sfondo primario)
                    color: colorScheme.onPrimary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Email con container arrotondato
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    // Sfondo del badge email
                    color: colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    email,
                    style: TextStyle(
                      fontSize: 13,
                      // Colore testo email
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Main Page (Tasks of the day)
          _buildMenuTile(
            context: context,
            icon: Icons.today_rounded,
            title: 'Main Page',
            subtitle: 'Tasks of the day',
            route: '/',
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go('/');
            },
          ),

          _buildDivider(),

          // Todo Lists
          _buildMenuTile(
            context: context,
            icon: Icons.checklist_rounded,
            title: 'Todo Lists',
            route: '/',
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go('/');
            },
          ),

          // Calendar View
          _buildMenuTile(
            context: context,
            icon: Icons.calendar_month_rounded,
            title: 'Calendar View',
            route: AppRouter.calendar,
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go(AppRouter.calendar);
            },
          ),

          // My Invitations
          _buildMenuTile(
            context: context,
            icon: Icons.mail_rounded,
            title: 'My Invitations',
            route: AppRouter.invitations,
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go(AppRouter.invitations);
            },
          ),

          _buildDivider(),

          // Profile
          _buildMenuTile(
            context: context,
            icon: Icons.person_rounded,
            title: 'Profile',
            route: AppRouter.account,
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go(AppRouter.account);
            },
          ),

          _buildDivider(),

          // Switch Tema
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: Icon(
                context.watch<ThemeProvider>().isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: colorScheme.primary,
              ),
              title: Text(
                // Usiamo un operatore ternario per cambiare il testo
                context.watch<ThemeProvider>().isDarkMode
                    ? 'Modalità Scura' // Testo se isDarkMode è true
                    : 'Modalità Chiara', // Testo se isDarkMode è false
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Switch(
                value: context.watch<ThemeProvider>().isDarkMode,
                onChanged: (bool newValue) {
                  context.read<ThemeProvider>().toggleTheme(newValue);
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Log Out con stile evidenziato
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Material(
              // Sfondo del bottone Log Out (usa i colori di errore del tema)
              color: colorScheme.errorContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (Scaffold.of(context).isDrawerOpen) {
                    Navigator.of(context).pop();
                  }
                  _handleLogout();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      // Icona Log Out (usa i colori di errore del tema)
                      Icon(Icons.logout_rounded, color: colorScheme.error),
                      const SizedBox(width: 16),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          // Testo Log Out (usa i colori di errore del tema)
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget helper per creare voci di menu uniformi
  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required String route,
    required VoidCallback onTap,
  }) {
    final isActive = _isRouteActive(context, route);
    // Prendo il colorScheme una sola volta
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        // Sfondo tile (attivo o trasparente)
        color: isActive
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // Sfondo icona (attivo o inattivo)
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    // Colore icona
                    color: isActive
                        ? colorScheme
                            .onPrimary // Colore su primario (es. bianco)
                        : colorScheme.primary, // Colore primario
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w600,
                          // Colore testo (attivo o standard)
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            // Colore sottotitolo
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper per i divisori
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Divider(
        thickness: 1,
        // Colore divisore
        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
      ),
    );
  }
}
