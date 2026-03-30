import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<dynamic>> favoritesFuture;

  @override
  void initState() {
    super.initState();
    favoritesFuture = fetchFavorites();
  }

  Future<List<dynamic>> fetchFavorites() async {
    if (currentUserId == null) {
      throw Exception('Пользователь не выбран');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/favorites/$currentUserId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Ошибка загрузки избранного: ${response.body}');
    }
  }

  Future<void> removeFromFavorites(int productId) async {
    if (currentUserId == null) {
      throw Exception('Пользователь не выбран');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/favorites/remove'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': currentUserId,
        'product_id': productId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Не удалось удалить из избранного');
    }
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Не удалось открыть ссылку');
    }
  }

  Future<void> refreshFavorites() async {
    setState(() {
      favoritesFuture = fetchFavorites();
    });
  }

  Widget buildOfferCard(Map<String, dynamic> offer) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Color(0xFF2F6BFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer['store'] ?? 'Магазин',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  offer['price'] != null
                      ? 'Цена: ${offer['price']} ₽'
                      : 'Цена не указана',
                  style: const TextStyle(color: Color(0xFF374151)),
                ),
                const SizedBox(height: 4),
                Text(
                  offer['in_stock'] == true ? 'В наличии' : 'Нет в наличии',
                  style: TextStyle(
                    color: offer['in_stock'] == true
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () async {
              try {
                await openUrl(offer['url']);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
  }

  Widget buildFavoriteCard(Map<String, dynamic> item) {
    final offers = item['offers'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['product_name'] ?? '',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildTag('Бренд: ${item['brand']}'),
                buildTag('Категория: ${item['category']}'),
                buildTag('Модель: ${item['model']}'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ссылки на магазины',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (offers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Нет предложений магазинов'),
              )
            else
              ...offers.map(
                (offer) => buildOfferCard(
                  Map<String, dynamic>.from(offer),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await removeFromFavorites(item['product_id']);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Удалено из избранного'),
                      ),
                    );
                    await refreshFavorites();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Удалить товар'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: FutureBuilder<List<dynamic>>(
              future: favoritesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Ошибка загрузки избранного: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(child: Text('Избранное пустое'));
                }

                return RefreshIndicator(
                  onRefresh: refreshFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = Map<String, dynamic>.from(items[index]);
                      return buildFavoriteCard(item);
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