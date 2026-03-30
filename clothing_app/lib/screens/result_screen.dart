import 'package:flutter/material.dart';
import 'products_screen.dart';

class ResultScreen extends StatefulWidget {
  final String brand;
  final String model;
  final String category;

  const ResultScreen({
    super.key,
    required this.brand,
    required this.model,
    required this.category,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool isPageLoading = true;

  @override
  void initState() {
    super.initState();
    simulatePageLoading();
  }

  Future<void> simulatePageLoading() async {
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() {
      isPageLoading = false;
    });
  }

  Widget buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2F6BFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 3),
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
    );
  }

  Widget buildSkeletonLine({
    required double width,
    double height = 14,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget buildSkeletonInfoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSkeletonLine(width: 80, height: 12),
                const SizedBox(height: 8),
                buildSkeletonLine(width: 170, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSkeletonButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget buildLoadingContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                buildSkeletonLine(width: 220, height: 22),
              ],
            ),
            const SizedBox(height: 18),
            buildSkeletonInfoCard(),
            buildSkeletonInfoCard(),
            buildSkeletonInfoCard(),
            const SizedBox(height: 10),
            buildSkeletonButton(),
            const SizedBox(height: 20),
            buildSkeletonLine(width: 140, height: 18),
            const SizedBox(height: 14),
            buildSkeletonButton(),
            const SizedBox(height: 12),
            buildSkeletonButton(),
          ],
        ),
      ),
    );
  }

  Widget buildReadyContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF2F6BFF),
                ),
                SizedBox(width: 10),
                Text(
                  'Результат распознавания',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Проверьте найденные данные и выберите следующее действие.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            buildInfoRow(
              icon: Icons.workspace_premium_outlined,
              label: 'Бренд',
              value: widget.brand,
            ),
            buildInfoRow(
              icon: Icons.checkroom_outlined,
              label: 'Модель',
              value: widget.model,
            ),
            buildInfoRow(
              icon: Icons.category_outlined,
              label: 'Категория',
              value: widget.category,
            ),
            const SizedBox(height: 20),
            const Text(
              'Что дальше',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Можно перейти к предложениям магазинов или вернуться и загрузить другое фото.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductsScreen(model: widget.model),
                    ),
                  );
                },
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Найти товары'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Загрузить другое фото'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  foregroundColor: const Color(0xFF1A1D29),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isPageLoading
                      ? buildLoadingContent()
                      : buildReadyContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}