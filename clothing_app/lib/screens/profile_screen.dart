import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'auth_screen.dart';
import 'history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    currentUserId = null;
    currentUserName = null;
    currentUserEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  Widget buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2F6BFF),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHistoryCard(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HistoryScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF2F6BFF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'История',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Посмотреть последние результаты распознавания.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = currentUserId?.toString() ?? '—';
    final name = currentUserName ?? 'Пользователь';
    final email = currentUserEmail ?? 'Не указан';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2F6BFF),
                                Color(0xFF5B8CFF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 58,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'ID пользователя: $userId',
                            style: const TextStyle(
                              color: Color(0xFF2F6BFF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                buildInfoTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Имя',
                  value: name,
                ),
                buildInfoTile(
                  icon: Icons.alternate_email_rounded,
                  title: 'Email',
                  value: email,
                ),
                const SizedBox(height: 4),
                buildHistoryCard(context),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Выйти'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}