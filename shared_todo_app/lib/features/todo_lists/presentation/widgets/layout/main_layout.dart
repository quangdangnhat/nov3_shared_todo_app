import 'package:flutter/material.dart';

import '../../../../../config/responsive.dart';
import '../../../../../core/widgets/app_drawer.dart';

/// Layout principale dell'app con sidebar persistente.
/// Questo widget avvolge tutte le schermate per mantenere
/// la sidebar sempre visibile su tablet/desktop.
class MainLayout extends StatelessWidget {
  /// Il contenuto della pagina corrente (child route)
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      // Drawer SOLO su mobile (si apre/chiude con hamburger)
      drawer: isMobile ? const AppDrawer() : null,
      body: Row(
        children: [
          // Sidebar fissa SOLO su tablet/desktop
          if (!isMobile)
            Container(
              width: ResponsiveLayout.responsive<double>(
                context,
                mobile: 0,
                tablet: 280,
                desktop: 320,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: const AppDrawer(),
            ),

          // Contenuto principale (pagina corrente)
          Expanded(child: child),
        ],
      ),
    );
  }
}
