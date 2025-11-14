// coverage:ignore-file

import 'package:flutter/material.dart';
import '../../../../config/responsive.dart';
import 'login_form.dart';

class LoginCardLayout extends StatelessWidget {
  final double maxWidth;

  const LoginCardLayout({
    super.key,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveLayout.isTablet(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/login_image.png',
                    height: isTablet ? 280 : 200,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: const LoginForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
