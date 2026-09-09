# Cómo mejorar la experiencia de carga de una lista de productos en Flutter

Un `CircularProgressIndicator` en pantalla completa es funcional, pero genera una experiencia percibida como lenta y genérica. Hay varias estrategias que puedes combinar para mejorar esto significativamente. Te las explico en orden de impacto y complejidad.

---

## 1. Skeleton screens (la mejora más impactante)

En lugar de mostrar un spinner mientras no hay datos, muestra la estructura visual de la pantalla con contenido simulado animado. El usuario percibe que la app ya "cargó" aunque los datos reales aún no llegaron.

### Opción A — Paquete `skeletonizer` (recomendado)

```yaml
# pubspec.yaml
dependencies:
  skeletonizer: ^1.1.1
```

```dart
import 'package:skeletonizer/skeletonizer.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Con Riverpod AsyncNotifierProvider:
    final asyncProducts = ref.watch(productsProvider);

    return asyncProducts.when(
      loading: () => _ProductList(
        products: Product.placeholders(8), // lista de productos falsos
        isLoading: true,
      ),
      error: (e, _) => const _ErrorView(),
      data: (products) => _ProductList(products: products, isLoading: false),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;

  const _ProductList({required this.products, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(products[index]),
      ),
    );
  }
}
```

Crea un constructor de placeholder en tu modelo:

```dart
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required double price,
    String? imageUrl,
  }) = _Product;

  // Datos falsos que tienen la forma visual correcta
  static Product placeholder() => const Product(
    id: 'placeholder',
    name: 'Nombre del producto aquí',
    price: 99.99,
    imageUrl: null,
  );

  static List<Product> placeholders(int count) =>
      List.generate(count, (_) => placeholder());

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
```

**Por qué funciona:** El cerebro humano percibe el skeleton como "progreso". El usuario ve la estructura de lo que va a aparecer, lo que reduce la ansiedad de espera. Apple y Google lo usan en sus apps nativas por esta razón.

---

### Opción B — Shimmer manual con el paquete `shimmer`

Si quieres más control visual o no quieres usar `skeletonizer`:

```yaml
dependencies:
  shimmer: ^3.0.0
```

```dart
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder de imagen
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 180,
                color: Colors.white,
              ),
            ),
            // Placeholder de texto
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 120, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Uso mientras carga:
ListView.builder(
  itemCount: 8,
  itemBuilder: (_, __) => const ProductCardSkeleton(),
)
```

---

## 2. Aparición escalonada al llegar los datos

Cuando los datos llegan, en lugar de que aparezcan de golpe, los items entran uno a uno con animación. Esto se siente mucho más pulido.

```yaml
dependencies:
  flutter_staggered_animations: ^1.1.1
```

```dart
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

AnimationLimiter(
  child: ListView.builder(
    itemCount: products.length,
    itemBuilder: (context, index) {
      return AnimationConfiguration.staggeredList(
        position: index,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 24.0,
          child: FadeInAnimation(
            child: ProductCard(products[index]),
          ),
        ),
      );
    },
  ),
)
```

**Por qué funciona:** La aparición escalonada guía la atención del usuario de arriba hacia abajo, creando una sensación de fluidez en lugar de un "parpadeo" de contenido.

---

## 3. Cachear los datos para que la próxima vez sea instantáneo

Si el usuario ya visitó la pantalla antes, no tiene sentido que vea el loader otra vez. Con Riverpod, los providers guardan el estado entre navegaciones por defecto si el widget permanece en el árbol. Para persistencia entre sesiones:

```dart
// Con Riverpod + keep alive
@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    // Mantener el estado vivo aunque el widget se desmonte
    ref.keepAlive();
    return _repository.getProducts();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
```

Para persistencia entre arranques de la app, combina con `Hive` o `SharedPreferences`:

```dart
@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    ref.keepAlive();

    // 1. Devuelve caché local inmediatamente si existe
    final cached = await _localSource.getProducts();
    if (cached.isNotEmpty) {
      // Actualiza en background sin bloquear la UI
      _refreshInBackground();
      return cached;
    }

    // 2. Si no hay caché, va a la API
    final products = await _remoteSource.getProducts();
    await _localSource.saveProducts(products);
    return products;
  }

  void _refreshInBackground() {
    Future.microtask(() async {
      final products = await _remoteSource.getProducts();
      await _localSource.saveProducts(products);
      ref.invalidateSelf();
    });
  }
}
```

**Por qué funciona:** El patrón "cache-then-network" (o stale-while-revalidate) es el estándar de las apps nativas modernas. El usuario ve contenido de inmediato y los datos se actualizan silenciosamente.

---

## 4. Pull-to-refresh en lugar de recargar toda la pantalla

Si el usuario ya tiene datos y quiere actualizarlos, dáselo sin interrumpir la experiencia:

```dart
RefreshIndicator(
  onRefresh: () => ref.read(productsProvider.notifier).refresh(),
  child: ListView.builder(
    // ...
  ),
)
```

---

## 5. Estado de error con retry — no dejes al usuario varado

Si la API falla, muestra un mensaje claro con un botón para reintentar. Nunca un error vacío.

```dart
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar los productos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
```

---

## Resumen — Orden de implementación recomendado

| Prioridad | Mejora | Impacto | Esfuerzo |
|-----------|--------|---------|---------|
| 1 | Skeleton screens con `skeletonizer` | Alto | Bajo |
| 2 | `keepAlive()` en el provider | Alto | Muy bajo |
| 3 | Aparición escalonada con `flutter_staggered_animations` | Medio | Bajo |
| 4 | Caché local con Hive | Alto | Medio |
| 5 | Pull-to-refresh | Medio | Muy bajo |
| 6 | Estado de error con retry | Medio | Bajo |

**La combinación más efectiva con menos esfuerzo:** skeleton screens + `ref.keepAlive()`. Con estos dos cambios, la primera carga se siente rápida y estructurada, y las cargas subsiguientes son instantáneas.

---

## Ejemplo completo integrado

```dart
// products_screen.dart
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: asyncProducts.when(
        loading: () => Skeletonizer(
          enabled: true,
          child: _buildList(Product.placeholders(8), context),
        ),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.invalidate(productsProvider),
        ),
        data: (products) => RefreshIndicator(
          onRefresh: () => ref.read(productsProvider.notifier).refresh(),
          child: AnimationLimiter(
            child: _buildList(products, context),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Product> products, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
        position: index,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 24,
          child: FadeInAnimation(
            child: ProductCard(products[index]),
          ),
        ),
      ),
    );
  }
}
```

Con este enfoque pasas de una pantalla en negro con un spinner, a una experiencia donde el usuario siempre ve contenido —real o estructural— y la app se siente rápida desde el primer uso.
