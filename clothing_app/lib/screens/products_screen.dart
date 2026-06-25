import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class ProductsScreen extends StatefulWidget {
  final String model;

  const ProductsScreen({super.key, required this.model});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<dynamic>> productsFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProducts();
  }

  Future<List<dynamic>> fetchProducts() async {
    final response = await http.post(
      Uri.parse('$baseUrl/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'model': widget.model}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Ошибка загрузки: ${response.body}');
    }
  }

  Future<void> addToFavorites(int productId) async {
    if (currentUserId == null) {
      throw Exception('Пользователь не выбран');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/favorites/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': currentUserId,
        'product_id': productId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Не удалось добавить в избранное');
    }
  }

  // --- ЭТОТ МЕТОД ИСПРАВЛЕН ---
  Future<void> openUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      throw Exception('Ссылка на товар отсутствует');
    }
    
    String formattedUrl = urlString;
    if (!formattedUrl.startsWith('http')) {
      formattedUrl = 'https://$formattedUrl';
    }

    final uri = Uri.parse(formattedUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Не удалось открыть ссылку: $formattedUrl');
    }
  }

  Widget buildHeader(Map<String, dynamic> firstItem) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              firstItem['product_name'] ?? widget.model,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5C4C48),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildChip(Icons.workspace_premium_outlined,
                    firstItem['brand'] ?? 'Не указан'),
                buildChip(
                    Icons.category_outlined, firstItem['category'] ?? 'Не указана'),
                buildChip(Icons.checkroom_outlined, widget.model),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5E5D8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFD4A89E)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget buildOfferCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFFD4A89E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['store'] ?? 'Магазин',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            buildMetaRow('Цена', '${item['price']} ₽'),
            buildMetaRow(
              'Наличие',
              item['in_stock'] == true ? 'В наличии' : 'Нет в наличии',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                // --- ЭТОТ ВЫЗОВ ОБНОВЛЕН ---
                onPressed: () async {
                  try {
                    await openUrl(item['url']);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть магазин'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: Color(0xFFF5E5D8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFFA89B95),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> handleAddToFavorites(int productId) async {
    try {
      await addToFavorites(productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар добавлен в избранное')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Где купить'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: FutureBuilder<List<dynamic>>(
              future: productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Ошибка загрузки данных: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(child: Text('Товары не найдены'));
                }

                final firstItem = items.first;
                final productId = firstItem['product_id'];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    buildHeader(firstItem),
                    const SizedBox(height: 16),
                    const Text(
                      'Предложения магазинов',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (item) => buildOfferCard(
                        Map<String, dynamic>.from(item),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => handleAddToFavorites(productId),
                        icon: const Icon(Icons.favorite_border_rounded),
                        label: const Text('Добавить в избранное'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}