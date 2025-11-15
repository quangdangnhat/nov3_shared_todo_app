import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/router/app_router.dart';
import '../../data/account_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _accountService = AccountService();
  User? _user;

  // ✅ Override locale dell'email per aggiornare subito la UI
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
      // Se l'utente viene ricaricato (es. dopo riapertura schermata),
      // aggiorniamo anche l'override se l'email è cambiata.
      if (_user?.email != null) {
        _overrideEmail = _user!.email;
      }
    });
  }

  Future<bool> _confirmAction(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showChangeUsernameDialog() async {
    final currentUsername = (_user?.userMetadata?['username'] as String?) ?? '';
    final controller = TextEditingController(text: currentUsername);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = controller.text.trim();

              if (newUsername.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a username.'),
                  ),
                );
                return;
              }

              final confirm = await _confirmAction(
                'Change username',
                'Are you sure you want to change your username?',
              );

              if (!confirm) return;

              try {
                await _accountService.updateUsername(newUsername);
                await _loadUser();

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Username updated')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeEmailDialog() async {
    final newEmailController = TextEditingController();
    final currentPasswordController = TextEditingController();

    // 👁️ visibilità password (solo per questo dialog)
    final passwordVisible = ValueNotifier<bool>(false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit email'),
        content: ValueListenableBuilder<bool>(
          valueListenable: passwordVisible,
          builder: (context, isVisible, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newEmailController,
                decoration: const InputDecoration(labelText: 'New email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currentPasswordController,
                obscureText: !isVisible,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      passwordVisible.value = !isVisible;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = newEmailController.text.trim();
              final currentPassword = currentPasswordController.text;

              if (newEmail.isEmpty || currentPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in both fields.'),
                  ),
                );
                return;
              }

              try {
                final currentUser = Supabase.instance.client.auth.currentUser;

                if (currentUser == null || currentUser.email == null) {
                  throw Exception('No logged in user');
                }

                await Supabase.instance.client.auth.signInWithPassword(
                  email: currentUser.email!,
                  password: currentPassword,
                );

                await _accountService.updateEmail(newEmail);
                await _loadUser();

                // ✅ Aggiorniamo subito la UI con la nuova email
                if (mounted) {
                  setState(() {
                    _overrideEmail = newEmail;
                  });
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email updated')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged in user.')),
      );
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // 👁️ visibilità password per i 3 campi
    final currentPasswordVisible = ValueNotifier<bool>(false);
    final newPasswordVisible = ValueNotifier<bool>(false);
    final confirmPasswordVisible = ValueNotifier<bool>(false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: currentPasswordVisible,
              builder: (context, isVisible, __) => TextField(
                controller: currentPasswordController,
                obscureText: !isVisible,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      currentPasswordVisible.value = !isVisible;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: newPasswordVisible,
              builder: (context, isVisible, __) => TextField(
                controller: newPasswordController,
                obscureText: !isVisible,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      newPasswordVisible.value = !isVisible;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: confirmPasswordVisible,
              builder: (context, isVisible, __) => TextField(
                controller: confirmPasswordController,
                obscureText: !isVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      confirmPasswordVisible.value = !isVisible;
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword = currentPasswordController.text;
              final newPassword = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields.'),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New passwords do not match.'),
                  ),
                );
                return;
              }

              final confirm = await _confirmAction(
                'Change password',
                'Are you sure you want to change your password?',
              );

              if (!confirm) return;

              try {
                // ✅ NESSUN re-login qui: usiamo solo la sessione corrente
                await _accountService.updatePassword(newPassword);

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user ?? Supabase.instance.client.auth.currentUser;
    final username =
        (user?.userMetadata?['username'] as String?) ?? 'Unknown user';

    // ✅ Usiamo l'override se presente, altrimenti la mail dell'user
    final email = _overrideEmail ?? user?.email ?? '—';

    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRouter.home);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(initial, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              username,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Username'),
            subtitle: Text(username),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.edit, color: Colors.blueGrey),
              ],
            ),
            onTap: _showChangeUsernameDialog,
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.edit, color: Colors.blueGrey),
              ],
            ),
            onTap: _showChangeEmailDialog,
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Password'),
            subtitle: const Text('••••••••'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.edit, color: Colors.blueGrey),
              ],
            ),
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Account'),
            onPressed: () async {
              // 🔒 Conferma prima
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account?'),
                  content: const Text(
                    'This action is permanent. Are you sure you want to delete your account?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (ok != true) return;

              try {
                final supabase = Supabase.instance.client;

                // ☁️ Chiamiamo la Edge Function `delete-user`
                final response = await supabase.functions.invoke(
                  'delete-user',
                  method: HttpMethod.post,
                  body: {}, // non servono parametri
                );

                if (response.status != 200) {
                  throw Exception('Delete function error: ${response.data}');
                }

                // 🚪 Logout dopo la cancellazione
                await supabase.auth.signOut();

                if (!context.mounted) return;

                // 🔁 Torni alla schermata di login
                context.goNamed(AppRouter.login);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted successfully'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error while deleting account: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
