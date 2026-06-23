import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginMode = true;
  bool isLoading = false;
  bool obscurePassword = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> saveUserToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    if (currentUserId != null) {
      await prefs.setInt('user_id', currentUserId!);
    }
    if (currentUserName != null) {
      await prefs.setString('user_name', currentUserName!);
    }
    if (currentUserEmail != null) {
      await prefs.setString('user_email', currentUserEmail!);
    }
    if (currentUserRole != null) {
      await prefs.setString('user_role', currentUserRole!);
    }
  }

  Future<void> submit() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!isLoginMode && name.isEmpty) {
      showMessage('Введите имя');
      return;
    }

    if (email.isEmpty) {
      showMessage('Введите email');
      return;
    }

    if (password.isEmpty) {
      showMessage('Введите пароль');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = isLoginMode ? '$baseUrl/login' : '$baseUrl/register';

      final body = isLoginMode
          ? {'email': email, 'password': password}
          : {'name': name, 'email': email, 'password': password};

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['user'];

        currentUserId = user['user_id'];
        currentUserName = user['name'];
        currentUserEmail = user['email'];
        currentUserRole = user['role']?.toString() ?? 'user';

        await saveUserToLocalStorage();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLoginMode
                  ? 'Вход выполнен успешно'
                  : 'Регистрация выполнена успешно',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        final errorText = data['detail']?.toString() ?? 'Неизвестная ошибка';
        showMessage(errorText);
      }
    } catch (e) {
      showMessage('Ошибка соединения: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget buildFormBlock(String title, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFA89B95),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            if (!isLoginMode) ...[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : submit,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(isLoginMode ? 'Войти' : 'Зарегистрироваться'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        setState(() {
                          isLoginMode = !isLoginMode;
                        });
                      },
                child: Text(
                  isLoginMode
                      ? 'Нет аккаунта? Зарегистрироваться'
                      : 'Уже есть аккаунт? Войти',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isLoginMode ? 'Вход в аккаунт' : 'Регистрация';
    final subtitle = isLoginMode
        ? 'Войдите, чтобы сохранять данные аккаунта и просматривать историю распознавания.'
        : 'Создайте аккаунт, чтобы пользоваться приложением на постоянной основе.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: buildFormBlock(title, subtitle),
            ),
          ),
        ),
      ),
    );
  }
}
