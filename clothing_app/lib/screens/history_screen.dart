import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<dynamic>> historyFuture;
  bool isClearing = false;

  @override
  void initState() {
    super.initState();
    historyFuture = fetchHistory();
  }

  Future<List<dynamic>> fetchHistory() async {
    if (currentUserId == null) {
      throw Exception('Пользователь не авторизован');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/history/$currentUserId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Ошибка загрузки истории: ${response.body}');
    }
  }

  Future<void> refreshHistory() async {
    setState(() {
      historyFuture = fetchHistory();
    });
  }

  Future<void> clearHistory() async {
    if (currentUserId == null) {
      throw Exception('Пользователь не авторизован');
    }

    setState(() {
      isClearing = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/history/$currentUserId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка очистки истории: ${response.body}');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('История очищена'),
        ),
      );

      setState(() {
        historyFuture = fetchHistory();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isClearing = false;
      });
    }
  }

  Future<void> confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Очистить историю?'),
          content: const Text(
            'Все сохраненные результаты распознавания будут удалены.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C4C48),
              ),
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await clearHistory();
    }
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return 'Дата не указана';
    }

    try {
      final date = DateTime.parse(rawDate).toLocal();

      String twoDigits(int n) => n.toString().padLeft(2, '0');

      return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
          '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
    } catch (_) {
      return rawDate;
    }
  }

  Widget buildStatusChip(String? status) {
    final normalized = (status ?? '').toLowerCase();

    Color bgColor;
    Color textColor;
    String text;

    if (normalized == 'done') {
      bgColor = const Color(0xFFE8F5F0);
      textColor = const Color(0xFFB5D6A8);
      text = 'Успешно';
    } else if (normalized == 'processing') {
      bgColor = const Color(0xFFFFF5E6);
      textColor = const Color(0xFFE8A85E);
      text = 'Обработка';
    } else if (normalized == 'error') {
      bgColor = const Color(0xFFFFF0F0);
      textColor = const Color(0xFFE5B8B8);
      text = 'Ошибка';
    } else {
      bgColor = const Color(0xFFF8F7F5);
      textColor = const Color(0xFFA89B95);
      text = 'Неизвестно';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5E5D8)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5C4C48),
        ),
      ),
    );
  }

  void openResultScreen({
    required String brand,
    required String model,
    required String category,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          brand: brand,
          model: model,
          category: category,
        ),
      ),
    );
  }

  Widget buildHistoryCard(Map<String, dynamic> item) {
    final status = item['status']?.toString();
    final brand = item['brand']?.toString();
    final model = item['model']?.toString();
    final category = item['category']?.toString();

    final hasRecognitionData =
        brand != null && model != null && category != null;

    final canOpenResult =
        (status ?? '').toLowerCase() == 'done' && hasRecognitionData;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFFD4A89E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Результат распознавания',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatDate(item['request_date']?.toString()),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 16),
            if (hasRecognitionData) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  buildTag('Бренд: $brand'),
                  buildTag('Модель: $model'),
                  buildTag('Категория: $category'),
                ],
              ),
              if (canOpenResult) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      openResultScreen(
                        brand: brand,
                        model: model,
                        category: category,
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Открыть результат'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: const Color(0xFF1A1D29),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ] else ...[
              const Text(
                'Для этого запроса нет сохраненного результата распознавания.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 38,
                color: Color(0xFF2F6BFF),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'История пока пустая',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'После распознавания фото здесь появятся последние результаты.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> getLatestItems(List<dynamic> items) {
    if (items.length <= 15) {
      return items;
    }

    return items.take(15).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          IconButton(
            onPressed: isClearing ? null : confirmClearHistory,
            tooltip: 'Очистить историю',
            icon: isClearing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: FutureBuilder<List<dynamic>>(
              future: historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Ошибка загрузки истории: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                final latestItems = getLatestItems(items);

                if (latestItems.isEmpty) {
                  return buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: refreshHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: latestItems.length,
                    itemBuilder: (context, index) {
                      final item = Map<String, dynamic>.from(latestItems[index]);
                      return buildHistoryCard(item);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}