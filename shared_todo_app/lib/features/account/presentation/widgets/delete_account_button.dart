import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_todo_app/config/responsive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/router/app_router.dart';

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({super.key});

  Future<void> _handleDeleteAccount(BuildContext context) async {
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.functions.invoke(
        'delete-user',
        method: HttpMethod.post,
        body: {},
      );

      if (response.status != 200) {
        throw Exception('Delete function error: ${response.data}');
      }

      await supabase.auth.signOut();

      if (!context.mounted) return;

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
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveLayout.responsive<double>(
            context,
            mobile: 14,
            tablet: 16,
            desktop: 18,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.delete_forever),
      label: const Text('Delete Account'),
      onPressed: () => _handleDeleteAccount(context),
    );
  }
}
