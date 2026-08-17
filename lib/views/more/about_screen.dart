import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // App Logo
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // App Name
            Text(
              'Home Money',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Manage Your Money Easily',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8),

            Text('Version 1.0.0', style: theme.textTheme.bodySmall),

            const SizedBox(height: 32),

            // About Section
            _SectionCard(
              title: 'About the App',
              icon: Icons.info_outline,
              child: Text(
                'Home Money is a simple personal finance '
                'app that helps you track your income, '
                'expenses and monthly budgets in one place.',
                style: theme.textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 20),

            // Features
            _SectionCard(
              title: 'Features',
              icon: Icons.star_outline,
              child: Column(
                children: [
                  _FeatureTile(icon: Icons.add_card, title: 'Income Tracking'),
                  _FeatureTile(
                    icon: Icons.remove_circle_outline,
                    title: 'Expense Tracking',
                  ),
                  _FeatureTile(
                    icon: Icons.pie_chart_outline,
                    title: 'Monthly Budget',
                  ),
                  _FeatureTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Transaction History',
                  ),
                  _FeatureTile(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Support
            _SectionCard(
              title: 'Support',
              icon: Icons.support_agent,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.email_outlined,
                    title: 'Contact Us',
                    onTap: () {
                      // Open email
                    },
                  ),
                  _ActionTile(
                    icon: Icons.star_outline,
                    title: 'Rate App',
                    onTap: () {
                      // Open store
                    },
                  ),
                  _ActionTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy Policy',
                    onTap: () {
                      // Open privacy policy
                    },
                  ),
                  _ActionTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {
                      // Open terms
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text('2026 Home Money', style: theme.textTheme.bodySmall),

            const SizedBox(height: 4),

            Text('Developed by Nay Lin Htet', style: theme.textTheme.bodySmall),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
    );
  }
}
