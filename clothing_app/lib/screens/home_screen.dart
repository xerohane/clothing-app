import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? selectedImage;
  final picker = ImagePicker();
  bool isRecognizing = false;

  Future<void> pickImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  Future<Map<String, dynamic>> recognizeItem() async {
    if (selectedImage == null) {
      throw Exception('Сначала выбери фото');
    }

    if (currentUserId == null) {
      throw Exception('Пользователь не авторизован');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/recognize'),
    );

    request.fields['user_id'] = currentUserId.toString();

    final bytes = await selectedImage!.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: selectedImage!.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Ошибка распознавания: ${response.body}');
    }
  }

  void goToResult() async {
    try {
      if (selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала выбери фото')),
        );
        return;
      }

      setState(() {
        isRecognizing = true;
      });

      final result = await recognizeItem();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            brand: result['brand'],
            model: result['model'],
            category: result['category'],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRecognizing = false;
        });
      }
    }
  }

  Widget buildSelectedImage() {
    if (selectedImage == null) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 14),
            Text(
              'Фото ещё не выбрано',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Загрузи фото одежды, чтобы начать распознавание',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.network(
          selectedImage!.path,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.file(
        File(selectedImage!.path),
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isRecognizing ? null : pickImage,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Выбрать фото'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isRecognizing ? null : goToResult,
            icon: isRecognizing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
            label: Text(isRecognizing ? 'Распознаём...' : 'Распознать'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              foregroundColor: const Color(0xFF1A1D29),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск одежды'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildSelectedImage(),
                  const SizedBox(height: 18),
                  buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}