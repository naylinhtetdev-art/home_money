import 'package:flutter/material.dart';
import 'package:home_money/views/more/change_password.dart';
import 'package:home_money/views/more/edit_profile.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final displayName = user?.displayName ?? 'Home Money user';
    final email = user?.email ?? '';
    final avatarLetter = (user?.displayName ?? user?.email ?? 'U').isNotEmpty
        ? (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase()
        : 'U';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 30, child: Text(avatarLetter)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(email),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Preferences',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _tile(
            context,
            Icons.person_outline,
            'Profile details',
            'Name, phone, currency and language',
            onTap: () async {
              // TODO: navigate to profile edit
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _tile(
            context,
            Icons.notifications_outlined,
            'Notifications',
            'Daily reminders and budget alerts',
            onTap: () {
              // TODO: navigate to notification settings
            },
          ),
          Consumer<ThemeProvider>(
            builder: (_, p, __) {
              return SwitchListTile(
                value: p.themeMode == ThemeMode.dark,
                title: const Text('Dark mode'),
                secondary: const Icon(Icons.dark_mode_outlined),
                onChanged: (v) =>
                    p.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
              );
            },
          ),
          // Consumer<ThemeProvider>(
          //   builder: (_, p, _) => ListTile(
          //     leading: const Icon(Icons.brightness_auto_outlined),
          //     title: const Text('Theme mode'),
          //     trailing: DropdownButton<ThemeMode>(
          //       value: p.themeMode,
          //       underline: const SizedBox.shrink(),
          //       onChanged: (mode) {
          //         if (mode != null) {
          //           p.setThemeMode(mode);
          //         }
          //       },
          //       items: const [
          //         DropdownMenuItem(
          //           value: ThemeMode.system,
          //           child: Text('System'),
          //         ),
          //         DropdownMenuItem(
          //           value: ThemeMode.light,
          //           child: Text('Light'),
          //         ),
          //         DropdownMenuItem(
          //           value: ThemeMode.dark,
          //           child: Text('Dark'),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          const Divider(),
          const Text('Account', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _tile(
            context,
            Icons.lock_outline,
            'Change password',
            'Send a password reset email',
            onTap: () async {
              showChangePasswordDialog(context);

              // if (user?.email != null) {
              //   final ok = await auth.resetPassword(user!.email!);
              //   if (context.mounted) {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(
              //         content: Text(
              //           ok
              //               ? 'Password reset email sent.'
              //               : (auth.error ?? 'Unable to send reset email'),
              //         ),
              //       ),
              //     );
              //   }
              // }
            },
          ),
          _tile(
            context,
            Icons.info_outline,
            'About Home Money',
            'Personal and household finance manager',
            onTap: () {
              // TODO: show about dialog
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
