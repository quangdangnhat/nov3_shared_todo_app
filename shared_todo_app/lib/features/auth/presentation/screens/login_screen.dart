import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/responsive.dart';
import '../controllers/login_controller.dart';
import '../widgets/login_header.dart';
import '../widgets/login_card_layout.dart';
import '../widgets/login_desktop_layout.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Scaffold(
        body: Container(
          decoration: _buildGradientDecoration(context),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16.0),
                  const LoginHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ResponsiveLayout(
                      mobile: const LoginCardLayout(maxWidth: 400),
                      tablet: const LoginCardLayout(maxWidth: 550),
                      desktop: const LoginDesktopLayout(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          colorScheme.primary.withOpacity(0.1),
          colorScheme.surface,
          colorScheme.surface,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.3, 1.0],
      ),
    );
  }
}
