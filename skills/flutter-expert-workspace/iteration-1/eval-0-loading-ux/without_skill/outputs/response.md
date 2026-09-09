# Mejorando la experiencia de carga en Flutter: Más allá del CircularProgressIndicator

## El Problema

Cuando una pantalla carga datos desde una API y el usuario solo ve un `CircularProgressIndicator` por varios segundos, la experiencia es pobre porque:

1. El usuario no sabe cuánto tiempo faltará.
2. La pantalla se ve vacía y "rota".
3. Genera sensación de lentitud aunque el tiempo de carga sea normal.

---

## Soluciones Recomendadas (de menor a mayor impacto)

---

### 1. Skeleton Loading (Shimmer Effect) — Recomendado

En lugar de mostrar un spinner, muestra el "esqueleto" de la UI con un efecto de brillo animado. El usuario entiende de inmediato la estructura de lo que va a aparecer.

**Instala el paquete:**

```yaml
# pubspec.yaml
dependencies:
  shimmer: ^3.0.0
```

**Implementación:**

```dart
import 'package:shimmer/shimmer.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts(); // Llamada a la API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Productos')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonList(); // Skeleton en lugar de spinner
          }
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error);
          }
          return _buildProductList(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 8, // Muestra 8 items "fantasma"
      itemBuilder: (context, index) => _buildSkeletonItem(),
    );
  }

  Widget _buildSkeletonItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen placeholder
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título placeholder
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  // Subtítulo placeholder
                  Container(
                    height: 12,
                    width: 150,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  // Precio placeholder
                  Container(
                    height: 14,
                    width: 80,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(product: products[index]),
    );
  }

  Widget _buildErrorWidget(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Error al cargar los productos'),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() {
              _productsFuture = fetchProducts(); // Reintentar
            }),
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
```

---

### 2. Carga Progresiva con Paginación

Si la lista es larga, carga los primeros resultados rápido y añade más al hacer scroll.

```dart
class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final List<Product> _products = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final products = await fetchProducts(page: 1);
      setState(() {
        _products.addAll(products);
        _isLoading = false;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final products = await fetchProducts(page: _currentPage + 1);
      setState(() {
        _products.addAll(products);
        _currentPage++;
        _isLoadingMore = false;
        _hasMore = products.isNotEmpty;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeletonList(); // Skeleton en primera carga

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _products.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return Center(child: CircularProgressIndicator()); // Solo al final
          }
          return ProductCard(product: _products[index]);
        },
      ),
    );
  }
}
```

---

### 3. Caché Local con `shared_preferences` o `hive`

Muestra datos del caché inmediatamente mientras se actualiza en segundo plano.

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProductRepository {
  static const _cacheKey = 'cached_products';
  static const _cacheDuration = Duration(minutes: 5);

  Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    final cachedTime = prefs.getInt('${_cacheKey}_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Si hay caché válida, devuélvela inmediatamente
    if (cachedData != null &&
        now - cachedTime < _cacheDuration.inMilliseconds) {
      final list = (jsonDecode(cachedData) as List)
          .map((e) => Product.fromJson(e))
          .toList();
      return list;
    }

    // Sino, fetch desde API y guarda en caché
    final products = await fetchFromApi();
    await prefs.setString(_cacheKey, jsonEncode(products.map((e) => e.toJson()).toList()));
    await prefs.setInt('${_cacheKey}_time', now);
    return products;
  }
}
```

**Uso con stale-while-revalidate (muestra caché y actualiza en segundo plano):**

```dart
class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Muestra caché inmediatamente si existe
    final cached = await ProductRepository().getCachedProducts();
    if (cached.isNotEmpty) {
      setState(() {
        _products = cached;
        _isLoading = false; // ¡Ya no muestra el spinner!
      });
    }

    // 2. Actualiza desde API en segundo plano
    try {
      final fresh = await ProductRepository().fetchFromApi();
      if (mounted) {
        setState(() {
          _products = fresh;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Si falla, los datos del caché siguen mostrandose
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _products.isEmpty) {
      return _buildSkeletonList(); // Solo skeleton si no hay NADA que mostrar
    }
    return _buildProductList();
  }
}
```

---

### 4. Mejoras de UX Adicionales

#### A. Pull-to-Refresh

Permite al usuario actualizar manualmente:

```dart
RefreshIndicator(
  onRefresh: () async {
    await _loadData(forceRefresh: true);
  },
  child: ListView.builder(/* ... */),
)
```

#### B. Animación de entrada de los items

Cuando los datos aparecen, anímalos para que la transición sea suave:

```dart
class AnimatedProductCard extends StatefulWidget {
  final Product product;
  final int index;

  const AnimatedProductCard({required this.product, required this.index});

  @override
  _AnimatedProductCardState createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Retrasa la animación según el índice del item
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slideAnimation,
        child: ProductCard(product: widget.product),
      ),
    );
  }
}
```

#### C. Estado vacío claro

Si la API devuelve una lista vacía, muéstraselo al usuario:

```dart
Widget _buildContent(List<Product> products) {
  if (products.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No hay productos disponibles',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: _loadData,
            child: Text('Recargar'),
          ),
        ],
      ),
    );
  }
  return ListView.builder(/* ... */);
}
```

---

### 5. Usando Riverpod o BLoC (arquitectura más robusta)

Si ya usas gestión de estado, el skeleton se integra limpiamente:

**Con Riverpod:**

```dart
final productsProvider = FutureProvider<List<Product>>((ref) async {
  return await fetchProducts();
});

class ProductListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => _buildSkeletonList(), // Skeleton durante la carga
      error: (error, stack) => _buildErrorWidget(error),
      data: (products) => _buildProductList(products),
    );
  }
}
```

---

## Resumen de Estrategias

| Estrategia | Impacto UX | Complejidad | Cuándo usarla |
|---|---|---|---|
| Skeleton Loading | Alto | Baja | Siempre, como base |
| Caché local | Muy alto | Media | Listas que no cambian constantemente |
| Paginación | Alto | Media-Alta | Listas largas (>20 items) |
| Animación de entrada | Medio | Baja | Como complemento al skeleton |
| Pull-to-refresh | Medio | Muy baja | Siempre que los datos puedan cambiar |

---

## Recomendación Final

La combinación ideal es:

1. **Skeleton loading** en la primera carga (siempre).
2. **Caché local** para que al volver a entrar, los datos aparezcan instantáneamente.
3. **Pull-to-refresh** para que el usuario pueda actualizar cuando quiera.
4. **Manejo de errores** con botón de "Reintentar".

Esto transforma la experiencia de "pantalla rota con spinner" a una app que se siente rápida y profesional, incluso con conexiones lentas.
