import 'package:flutter/material.dart';
import 'package:shared_todo_app/config/responsive.dart';
import 'package:shared_todo_app/features/account/presentation/dialogs/change_password_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/account_service.dart';
import '../widgets/account_avatar.dart';
import '../widgets/account_info_card.dart';
import '../widgets/delete_account_button.dart';
import '../dialogs/change_email_dialog.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _accountService = AccountService();
  User? _user;
  String? _overrideEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final res = await Supabase.instance.client.auth.getUser();
    setState(() {
      _user = res.user;
      if (_user?.email != null) {
        _overrideEmail = _user!.email;
      }
    });
  }

  Future<void> _showChangeEmailDialog() async {
    final newEmail = await showChangeEmailDialog(
      context,
      accountService: _accountService,
    );

    if (newEmail != null) {
      setState(() {
        _overrideEmail = newEmail;
      });
      await _loadUser();
    }
  }

  Future<void> _showChangePasswordDialog() async {
    await showChangePasswordDialog(
      context,
      accountService: _accountService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user ?? Supabase.instance.client.auth.currentUser;
    final username =
        (user?.userMetadata?['username'] as String?) ?? 'Unknown user';
    final email = _overrideEmail ?? user?.email ?? '—';
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.responsive<double>(
              context,
              mobile: double.infinity,
              tablet: 600,
              desktop: 700,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.all(
              ResponsiveLayout.responsive<double>(
                context,
                mobile: 16,
                tablet: 24,
                desktop: 32,
              ),
            ),
            children: [
              const SizedBox(height: 8),
              AccountAvatar(username: username),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              AccountInfoCard(
                icon: Icons.person,
                title: 'Username',
                value: username,
              ),
              AccountInfoCard(
                icon: Icons.email,
                title: 'Email',
                value: email,
                onEdit: _showChangeEmailDialog,
              ),
              AccountInfoCard(
                icon: Icons.lock,
                title: 'Password',
                value: '••••••••',
                onEdit: _showChangePasswordDialog,
              ),
              const SizedBox(height: 32),
              DeleteAccountButton(),
            ],
          ),
        ),
      ),
    );
  }
}
