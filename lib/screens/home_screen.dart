import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'totp_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  String? _userEmail;
  List<String> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      final results = await Future.wait([
        Amplify.Auth.fetchUserAttributes(),
        _authService.getUserGroups(),
      ]);
      final attributes = results[0] as List<AuthUserAttribute>;
      final groups = results[1] as List<String>;
      final emailAttr = attributes.firstWhere(
        (a) => a.userAttributeKey == AuthUserAttributeKey.email,
        orElse: () => AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.email,
          value: user.username,
        ),
      );
      setState(() {
        _userEmail = emailAttr.value;
        _groups = groups;
        _isLoading = false;
      });
    } on Exception {
      setState(() {
        _userEmail = 'Unknown';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 96,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _userEmail ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Role badges
                    if (_groups.isNotEmpty)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: _groups
                            .map((g) => _RoleBadge(group: g))
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    // Role-specific content
                    _RoleContent(groups: _groups),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TotpSetupScreen(userEmail: _userEmail ?? ''),
                          ),
                        );
                        if (result == true && mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('TOTP MFA is now active on your account.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.security),
                      label: const Text('Set Up Authenticator App'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String group;
  const _RoleBadge({required this.group});

  Color get _color {
    switch (group) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        group.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      backgroundColor: _color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _RoleContent extends StatelessWidget {
  final List<String> groups;
  const _RoleContent({required this.groups});

  bool get _isAdmin => groups.contains('admin');
  bool get _isManager => groups.contains('manager') || _isAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Visible to all signed-in users
        _SectionCard(
          icon: Icons.dashboard_outlined,
          title: 'Dashboard',
          subtitle: 'Available to all users',
          color: Colors.blue,
        ),
        const SizedBox(height: 10),
        // Visible to managers and admins
        if (_isManager) ...[
          _SectionCard(
            icon: Icons.people_outline,
            title: 'Team Management',
            subtitle: 'Visible to managers and admins',
            color: Colors.orange,
          ),
          const SizedBox(height: 10),
        ],
        // Visible to admins only
        if (_isAdmin)
          _SectionCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin Panel',
            subtitle: 'Visible to admins only',
            color: Colors.red,
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(100)),
        borderRadius: BorderRadius.circular(10),
        color: color.withAlpha(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}
