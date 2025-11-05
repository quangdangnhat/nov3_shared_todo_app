import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/router/app_router.dart';

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
    final username = (user?.userMetadata?['username'] as String?) ?? 'No Username';
    final email = user?.email ?? 'No Email';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    final screenWidth = MediaQuery.of(context).size.width;

    
    final drawerWidth = screenWidth * 0.85;

    return Container(
      width: drawerWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header personalizzato moderno
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
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
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Username con stile moderno
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Email con container arrotondato
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
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
            route: '/', // TODO: cambia con la rotta corretta quando implementata
            onTap: () {
              // Chiudi il drawer solo su mobile
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
              // Chiudi il drawer solo su mobile
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
              // Chiudi il drawer solo su mobile
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
              // Chiudi il drawer solo su mobile
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
              // Chiudi il drawer solo su mobile
              if (Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go(AppRouter.account);
            },
          ),

          const SizedBox(height: 8),

          // Log Out con stile evidenziato
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Material(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Chiudi il drawer solo su mobile
                  if (Scaffold.of(context).isDrawerOpen) {
                    Navigator.of(context).pop();
                  }
                  _handleLogout();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 16),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isActive 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
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
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
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
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
      ),
    );
  }
}