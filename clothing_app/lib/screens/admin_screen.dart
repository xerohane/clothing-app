import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<Map<String, dynamic>> adminFuture;

  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController productController = TextEditingController();
  final TextEditingController offerPriceController = TextEditingController();
  final TextEditingController offerUrlController = TextEditingController();
  final TextEditingController offerColorController = TextEditingController();
  final TextEditingController offerSizeController = TextEditingController();
  final TextEditingController offerDescriptionController =
      TextEditingController();
  final TextEditingController offerImageUrlController = TextEditingController();
  final TextEditingController userSearchController = TextEditingController();

  int? selectedBrandId;
  int? selectedCategoryId;
  int? selectedModelId;
  int? selectedStoreId;
  bool offerInStock = true;

  bool isBrandLoading = false;
  bool isModelLoading = false;
  bool isOfferLoading = false;
  bool isUserActionLoading = false;
  String userActionType = '';
  String selectedUserRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    adminFuture = fetchAdminData();
  }

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    productController.dispose();
    offerPriceController.dispose();
    offerUrlController.dispose();
    offerColorController.dispose();
    offerSizeController.dispose();
    offerDescriptionController.dispose();
    offerImageUrlController.dispose();
    userSearchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchAdminData() async {
    if (currentUserId == null) {
      throw Exception('Пользователь не авторизован');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/metadata?admin_id=$currentUserId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки админ-данных: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> createBrand() async {
    final brandName = brandController.text.trim();
    if (brandName.isEmpty) {
      showSnackbar('Введите название бренда');
      return;
    }

    setState(() => isBrandLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/brands'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': currentUserId, 'brand_name': brandName}),
      );

      if (response.statusCode == 200) {
        brandController.clear();
        setState(() {
          adminFuture = fetchAdminData();
        });
        showSnackbar('Бренд добавлен');
      } else {
        final error = jsonDecode(response.body)['detail'] ?? response.body;
        showSnackbar('Ошибка: $error');
      }
    } catch (e) {
      showSnackbar('Ошибка сети: $e');
    } finally {
      setState(() => isBrandLoading = false);
    }
  }

  Future<void> createModel() async {
    final modelName = modelController.text.trim();
    if (modelName.isEmpty ||
        selectedBrandId == null ||
        selectedCategoryId == null) {
      showSnackbar('Заполните название, бренд и категорию');
      return;
    }

    setState(() => isModelLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/models'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admin_id': currentUserId,
          'model_name': modelName,
          'brand_id': selectedBrandId,
          'category_id': selectedCategoryId,
        }),
      );

      if (response.statusCode == 200) {
        modelController.clear();
        setState(() {
          selectedBrandId = null;
          selectedCategoryId = null;
          adminFuture = fetchAdminData();
        });
        showSnackbar('Модель добавлена');
      } else {
        final error = jsonDecode(response.body)['detail'] ?? response.body;
        showSnackbar('Ошибка: $error');
      }
    } catch (e) {
      showSnackbar('Ошибка сети: $e');
    } finally {
      setState(() => isModelLoading = false);
    }
  }

  Future<void> createOffer() async {
    final productName = productController.text.trim();
    final priceText = offerPriceController.text.trim();
    final productUrl = offerUrlController.text.trim();
    final color = offerColorController.text.trim();
    final size = offerSizeController.text.trim();
    final description = offerDescriptionController.text.trim();
    final imageUrl = offerImageUrlController.text.trim();

    if (productName.isEmpty ||
        selectedModelId == null ||
        selectedStoreId == null ||
        priceText.isEmpty ||
        productUrl.isEmpty) {
      showSnackbar('Заполните обязательные поля товара');
      return;
    }

    final price = double.tryParse(priceText.replaceAll(',', '.'));
    if (price == null) {
      showSnackbar('Некорректная цена');
      return;
    }

    setState(() => isOfferLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/offers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admin_id': currentUserId,
          'model_id': selectedModelId,
          'product_name': productName,
          'color': color,
          'size': size,
          'description': description,
          'image_url': imageUrl,
          'store_id': selectedStoreId,
          'price': price,
          'product_url': productUrl,
          'in_stock': offerInStock,
        }),
      );

      if (response.statusCode == 200) {
        productController.clear();
        offerPriceController.clear();
        offerUrlController.clear();
        offerColorController.clear();
        offerSizeController.clear();
        offerDescriptionController.clear();
        offerImageUrlController.clear();
        setState(() {
          selectedModelId = null;
          selectedStoreId = null;
          offerInStock = true;
          adminFuture = fetchAdminData();
        });
        showSnackbar('Товарное предложение добавлено');
      } else {
        final error = jsonDecode(response.body)['detail'] ?? response.body;
        showSnackbar('Ошибка: $error');
      }
    } catch (e) {
      showSnackbar('Ошибка сети: $e');
    } finally {
      setState(() => isOfferLoading = false);
    }
  }

  Future<void> changeUserRole(int userId, String currentRole) async {
    final nextRole = currentRole == 'admin' ? 'user' : 'admin';
    if (userId == currentUserId && nextRole == 'user') {
      showSnackbar('Нельзя понижать себя');
      return;
    }

    setState(() => isUserActionLoading = true);

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': currentUserId, 'role': nextRole}),
      );

      if (response.statusCode == 200) {
        setState(() {
          adminFuture = fetchAdminData();
        });
        showSnackbar('Роль пользователя обновлена');
      } else {
        final error = jsonDecode(response.body)['detail'] ?? response.body;
        showSnackbar('Ошибка: $error');
      }
    } catch (e) {
      showSnackbar('Ошибка сети: $e');
    } finally {
      setState(() => isUserActionLoading = false);
    }
  }

  Future<void> toggleUserBlock(int userId, bool isCurrentlyActive) async {
    if (userId == currentUserId) {
      showSnackbar('Нельзя блокировать себя');
      return;
    }

    setState(() => isUserActionLoading = true);

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/block'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admin_id': currentUserId,
          'is_active': !isCurrentlyActive,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          adminFuture = fetchAdminData();
        });
        showSnackbar(
          isCurrentlyActive ? 'Пользователь заблокирован' : 'Пользователь разблокирован',
        );
      } else {
        final error = jsonDecode(response.body)['detail'] ?? response.body;
        showSnackbar('Ошибка: $error');
      }
    } catch (e) {
      showSnackbar('Ошибка сети: $e');
    } finally {
      setState(() => isUserActionLoading = false);
    }
  }

  void showSnackbar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget buildStatItem(String title, String value, Color color) {
    return Card(
      color: const Color(0xFFF5F0F5),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8B7B8B)),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8B7B8B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F0F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8B7B8B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F0F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    );
  }

  Widget buildAddTab(
    List<dynamic> brands,
    List<dynamic> categories,
    List<dynamic> stores,
    List<dynamic> models,
    Map<String, dynamic> stats,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Статистика системы',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Wrap(
                  runSpacing: 12,
                  spacing: 12,
                  children: [
                    SizedBox(
                      width: 240,
                      child: buildStatItem(
                        'Пользователей',
                        stats['total_users'].toString(),
                        const Color(0xFFD4A89E),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: buildStatItem(
                        'Фото',
                        stats['total_photos'].toString(),
                        const Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: buildStatItem(
                        'Запросов',
                        stats['total_requests'].toString(),
                        const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),            side: BorderSide(color: Color(0xFFE5E7EB)),          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Добавить бренд'),
                const SizedBox(height: 14),
                buildTextField(
                  controller: brandController,
                  label: 'Название бренда',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB19CD5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isBrandLoading ? null : createBrand,
                    child: isBrandLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Добавить бренд'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Добавить модель'),
                const SizedBox(height: 14),
                buildTextField(
                  controller: modelController,
                  label: 'Название модели',
                ),
                const SizedBox(height: 14),
                buildDropdown<int>(
                  label: 'Бренд',
                  value: selectedBrandId,
                  items: brands
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item['brand_id'] as int,
                          child: Text(item['brand_name'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedBrandId = value),
                ),
                const SizedBox(height: 14),
                buildDropdown<int>(
                  label: 'Категория',
                  value: selectedCategoryId,
                  items: categories
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item['category_id'] as int,
                          child: Text(item['category_name'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedCategoryId = value),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB19CD5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isModelLoading ? null : createModel,
                    child: isModelLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Добавить модель'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          color: const Color(0xFFF5F0F5),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Добавить товарное предложение'),
                const SizedBox(height: 14),
                buildTextField(
                  controller: productController,
                  label: 'Название товара',
                ),
                const SizedBox(height: 14),
                buildDropdown<int>(
                  label: 'Модель',
                  value: selectedModelId,
                  items: models
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item['model_id'] as int,
                          child: Text(item['model_name'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedModelId = value),
                ),
                const SizedBox(height: 14),
                buildDropdown<int>(
                  label: 'Магазин',
                  value: selectedStoreId,
                  items: stores
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item['store_id'] as int,
                          child: Text(item['store_name'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedStoreId = value),
                ),
                const SizedBox(height: 14),
                buildTextField(controller: offerColorController, label: 'Цвет'),
                const SizedBox(height: 14),
                buildTextField(
                  controller: offerSizeController,
                  label: 'Размер',
                ),
                const SizedBox(height: 14),
                buildTextField(
                  controller: offerDescriptionController,
                  label: 'Описание',
                ),
                const SizedBox(height: 14),
                buildTextField(
                  controller: offerImageUrlController,
                  label: 'URL изображения',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 14),
                buildTextField(
                  controller: offerPriceController,
                  label: 'Цена',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                buildTextField(
                  controller: offerUrlController,
                  label: 'Ссылка на товар',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Checkbox(
                      value: offerInStock,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => offerInStock = value);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('В наличии'),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB19CD5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isOfferLoading ? null : createOffer,
                    child: isOfferLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Добавить товар'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildUsersTab(List<dynamic> users) {
    final search = userSearchController.text.trim().toLowerCase();
    final filteredUsers = users.where((userData) {
      final user = userData as Map<String, dynamic>;
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      final matchesSearch = search.isEmpty || name.contains(search) || email.contains(search);
      final matchesRole = selectedUserRoleFilter == 'all' || role == selectedUserRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildTextField(
          controller: userSearchController,
          label: 'Поиск по имени или email',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedUserRoleFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Все')),
                  DropdownMenuItem(value: 'admin', child: Text('Админы')),
                  DropdownMenuItem(value: 'user', child: Text('Пользователи')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedUserRoleFilter = value);
                },
                decoration: InputDecoration(
                  labelText: 'Фильтр',
                  labelStyle: const TextStyle(color: Color(0xFFA89B95)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '${filteredUsers.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD4A89E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (filteredUsers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Пользователи не найдены',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          )
        else
          ...filteredUsers.map((userData) {
            final user = userData as Map<String, dynamic>;
            final isSelf = user['user_id'] == currentUserId;
            // Нормализуем роль из БД ('admin' или 'user')
            final rawRole = (user['role'] ?? 'user').toString().toLowerCase().trim();
            final currentRole = rawRole == 'admin' ? 'admin' : 'user';
            final isActive = user['is_active'] as bool? ?? true;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: isActive ? Colors.white : const Color(0xFFF3F4F6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isActive ? const Color(0xFFF5E5D8) : const Color(0xFFF0E8F8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Opacity(
                            opacity: isActive ? 1.0 : 0.5,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: currentRole == 'admin'
                                  ? const Color(0xFF2F6BFF)
                                  : const Color(0xFF10B981),
                              child: Text(
                                (user['name'] ?? 'П')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] ?? 'Пользователь',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: isActive ? null : const Color(0xFF9CA3AF),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user['email'] ?? '',
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFFA89B95)
                                        : const Color(0xFFB5BAC0),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: currentRole == 'admin'
                                      ? const Color(0xFFEAF0FF)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentRole == 'admin' ? 'Администратор' : 'Пользователь',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: currentRole == 'admin'
                                        ? const Color(0xFFD4A89E)
                                        : const Color(0xFF374151),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFDFEBF8)
                                      : const Color(0xFFFFE5E5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isActive ? 'Активен' : 'Блокирован',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? const Color(0xFF0066CC)
                                        : const Color(0xFFCC0000),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isSelf) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4A89E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: isUserActionLoading
                                      ? null
                                      : () => changeUserRole(
                                            user['user_id'] as int,
                                            currentRole,
                                          ),
                                  child: isUserActionLoading
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          currentRole == 'администратор'
                                              ? 'Снять роль администратора'
                                              : 'Сделать администратором',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isActive
                                        ? const Color(0xFFCC0000)
                                        : const Color(0xFF10B981),
                                    side: BorderSide(
                                      color: isActive
                                          ? const Color(0xFFCC0000)
                                          : const Color(0xFF10B981),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: isUserActionLoading
                                      ? null
                                      : () => toggleUserBlock(
                                            user['user_id'] as int,
                                            isActive,
                                          ),
                                  child: Text(
                                    isActive ? 'Заблокировать' : 'Разблокировать',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, администратор ли текущий пользователь
    if (currentUserRole != 'admin') {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('Панель администратора'),
          backgroundColor: const Color(0xFFF5F7FB),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      size: 64,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Доступ запрещён',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Только администраторы могут входить в эту панель',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Текущая роль: $currentUserRole',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FB),
          foregroundColor: const Color(0xFF1A1D29),
          elevation: 0,
          title: const Text('Панель администратора'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  adminFuture = fetchAdminData();
                });
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF2F6BFF),
            labelColor: Color(0xFF1A1D29),
            unselectedLabelColor: Color(0xFF6B7280),
            tabs: const [
              Tab(text: 'Добавить'),
              Tab(text: 'Пользователи'),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: FutureBuilder<Map<String, dynamic>>(
                future: adminFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Ошибка: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final users = data['users'] as List<dynamic>;
                  final stats = data['stats'] as Map<String, dynamic>;
                  final brands = data['brands'] as List<dynamic>;
                  final categories = data['categories'] as List<dynamic>;
                  final stores = data['stores'] as List<dynamic>;
                  final models = data['models'] as List<dynamic>;

                  return TabBarView(
                    children: [
                      buildAddTab(brands, categories, stores, models, stats),
                      buildUsersTab(users),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
