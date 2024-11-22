import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
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

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<dynamic>> products;

  @override
  void initState() {
    super.initState();
    products = fetchProducts();
  }

  Future<List<dynamic>> fetchProducts() async {
    const String apiUrl = 'http://localhost:8000/products?limit=10&offset=0';
    try {
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
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Product Catalog'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found'));
          } else {
            final productList = snapshot.data!;
            return ListView.builder(
              itemCount: productList.length,
              itemBuilder: (context, index) {
                final product = productList[index];

            
                List<String> photoUrls = [];
                if (product['photos'] is List) {
                  photoUrls = List<String>.from(product['photos']);
                }

                return Card(
                  margin: const EdgeInsets.all(10.0),
                  child: ListTile(
                    leading: photoUrls.isNotEmpty
                        ? Image.network(
                            'http://localhost:8000/proxy_image?url=${Uri.encodeComponent(photoUrls[0].trim())}', // Proxy endpoint kullanımı
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
            );
          }
        },
      ),
    );
  }
}
