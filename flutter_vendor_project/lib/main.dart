import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ProductListPage(),
    );
  }
}

final productsProvider = FutureProvider<List<dynamic>>((ref) async {
  const String apiUrl = 'http://localhost:8000/products?limit=10&offset=0';
  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode == 200) {
    final Map<String, dynamic> decodedJson = jsonDecode(response.body);
    if (decodedJson['data'] != null) {
      List<dynamic> allProducts = [];
      decodedJson['data'].forEach((vendor, products) {
        allProducts.addAll(products);
      });
      return allProducts;
    } else {
      throw Exception('Invalid data format: "data" key is missing');
    }
  } else {
    throw Exception('Failed to load products. Status code: ${response.statusCode}');
  }
});

class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsyncValue = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Product Catalog'),
      ),
      body: productAsyncValue.when(
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            List<String> photoUrls = [];
            if (product['photos'] is List) {
              photoUrls = List<String>.from(product['photos']);
            }

            return Card(
              margin: const EdgeInsets.all(10.0),
              child: ListTile(
                leading: photoUrls.isNotEmpty
                    ? Image.network(
                        'http://localhost:8000/proxy_image?url=${Uri.encodeComponent(photoUrls[0].trim())}',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print("Image load error: $error");
                          return const Icon(Icons.broken_image);
                        },
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(product['name'] ?? 'Unknown Product'),
                subtitle: Text(product['description'] ?? 'No description'),
                trailing: Text(
                  product['price'] != null
                      ? '\$${product['price']}'
                      : 'Price not available',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
        error: (e, stack) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
