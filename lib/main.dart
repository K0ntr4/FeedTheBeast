import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

void main() async {
  // Fetch product information
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'FeedTheBeast', url: 'https://github.com/K0ntr4/FeedTheBeast');

  OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
    OpenFoodFactsLanguage.ENGLISH
  ];
  OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.GERMANY;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Allergene Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 17, 153, 187)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "Find allergenes in Product by Barcode"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String productId = '';
  String productName = '';
  String error = '';
  List<String> allergens = [];

  void _scan () async {
    error = '';
    var res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      )
    );
    if (res is String && int.parse(res) != -1) {
      setState(() {
        productId = res;
      });
      _findAllergens(productId);
    }
  }

  void _findAllergens (String productId) async {
    ProductQueryConfiguration config = ProductQueryConfiguration(
      productId,
      version: ProductQueryVersion.v3,
    );
    ProductResultV3 product = await OpenFoodAPIClient.getProductV3(config);
    if (product.product == null) {
      setState(() {
        error = 'Product not found.';
      });
      return;
    }
    // Get allergenes
    setState(() {
      allergens = product.product!.allergens?.names ?? [];
      productName = product.product!.productName ?? 'Unknown Porduct';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (error.isNotEmpty) Text(error, style: TextStyle(color: Colors.red)),
            if (error.isEmpty && productId.isNotEmpty) ...[
              if (productName.isNotEmpty) Text('Allergens in $productName:'),
              if (productName.isEmpty) const Text('Allergens:'),
              for (var allergen in allergens) Text(allergen),
            ]
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scan,
        tooltip: 'Scan Barcode',
        child: const Icon(Icons.camera),
      ),
    );
  }
}
