import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/models/user_model.dart';
import 'package:oneai/providers/auth_provider.dart';
import 'package:oneai/screens/auth/login_screen.dart';
import 'package:oneai/utils/platform_adaptive.dart';
import 'package:oneai/utils/responsive.dart';
import 'package:oneai/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final padding = Responsive.responsivePadding(context);
    final isDesktop = Responsive.isDesktop(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: PlatformAdaptive.appBar(
        context: context,
        title: 'Profile',
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // User avatar
                  _buildUserAvatar(user, context),
                  const SizedBox(height: 24),

                  // User info
                  _buildUserInfo(user, context),
                  const SizedBox(height: 32),

                  // Account actions
                  _buildAccountActions(context, authProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user, BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: user.avatarUrl != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.network(
              user.avatarUrl!,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  isApple ? CupertinoIcons.person : Icons.person,
                  size: 60,
                  color: AppTheme.primaryColor,
                );
              },
            ),
          )
              : Icon(
            isApple ? CupertinoIcons.person : Icons.person,
            size: 60,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.username,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(UserModel user, BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              context,
              isApple ? CupertinoIcons.person : Icons.person_outline,
              'Username',
              user.username,
            ),
            const Divider(),
            _buildInfoItem(
              context,
              isApple ? CupertinoIcons.mail : Icons.email_outlined,
              'Email',
              user.email,
            ),
            const Divider(),
            _buildInfoItem(
              context,
              isApple ? CupertinoIcons.time : Icons.access_time,
              'Last Login',
              user.lastLogin != null
                  ? '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year} at ${user.lastLogin!.hour}:${user.lastLogin!.minute.toString().padLeft(2, '0')}'
                  : 'First login',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, AuthProvider authProvider) {
    final isApple = PlatformAdaptive.isApplePlatform();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              isApple ? CupertinoIcons.lock : Icons.lock_outline,
              'Change Password',
                  () {
                // TODO: Implement change password functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change Password feature coming soon'),
                  ),
                );
              },
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              isApple ? CupertinoIcons.pen : Icons.edit_outlined,
              'Edit Profile',
                  () {
                // TODO: Implement edit profile functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit Profile feature coming soon'),
                  ),
                );
              },
              color: AppTheme.secondaryColor,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              isApple ? CupertinoIcons.arrow_right_square : Icons.logout,
              'Logout',
                  () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  }
                }
              },
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onPressed, {
        required Color color,
      }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: TextStyle(color: color),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          backgroundColor: color.withOpacity(0.1),
        ),
      ),
    );
  }
}
