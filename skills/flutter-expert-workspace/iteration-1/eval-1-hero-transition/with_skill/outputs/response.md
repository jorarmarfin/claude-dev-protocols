# Pantalla de Detalle de Producto con Transición Hero (estilo App Store)

## Qué vamos a construir

Una transición fluida al estilo de la App Store de Apple donde al tocar una tarjeta de producto en la lista, la imagen se "expande" hacia la pantalla de detalle de forma continua — sin un corte brusco. En Flutter esto se logra con el widget `Hero`, que comparte un elemento visual entre dos rutas durante la transición.

---

## Por qué `Hero` es la herramienta correcta aquí

`Hero` no es solo una animación — es un **shared element transition**: Flutter toma el widget visualmente de la pantalla de origen, lo "vuela" por encima del resto de la UI hacia su posición destino, y lo integra de manera seamless en la nueva pantalla. Es exactamente el mecanismo que usa la App Store al abrir una app desde la grilla.

La clave: el `tag` debe ser **único por ítem** (usamos el `id` del producto) y el widget hijo dentro de cada `Hero` debe ser visualmente idéntico para que la transición no haga "flash".

---

## Estructura de archivos

```
lib/
└── features/
    └── products/
        └── presentation/
            ├── screens/
            │   ├── product_list_screen.dart
            │   └── product_detail_screen.dart
            └── widgets/
                └── product_card.dart
```

---

## Modelo de datos

```dart
// lib/features/products/data/models/product.dart

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });
}

// Datos de ejemplo para no depender de red
final List<Product> demoProducts = [
  Product(
    id: '1',
    name: 'AirPods Pro',
    description:
        'Audio espacial personalizado con seguimiento dinámico de cabeza. '
        'La cancelación activa de ruido bloquea el ruido externo no deseado. '
        'El modo Transparencia permite escuchar el entorno.',
    price: 249.99,
    imageUrl: 'https://images.unsplash.com/photo-1588423771073-b8903fead0b1?w=800',
    category: 'Audio',
  ),
  Product(
    id: '2',
    name: 'MacBook Air M3',
    description:
        'Potencia extraordinaria con el chip M3. '
        'Hasta 18 horas de batería, pantalla Liquid Retina de 15 pulgadas '
        'y diseño ultradelgado sin ventilador.',
    price: 1299.99,
    imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800',
    category: 'Mac',
  ),
  Product(
    id: '3',
    name: 'iPhone 16 Pro',
    description:
        'Titanio. De grado espacial. El sistema de cámara Pro más avanzado. '
        'Chip A18 Pro con hardware de ray tracing. '
        'Botón de Acción y Camera Control.',
    price: 999.99,
    imageUrl: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800',
    category: 'iPhone',
  ),
];
```

---

## Pantalla de Lista

```dart
// lib/features/products/presentation/screens/product_list_screen.dart

import 'package:flutter/material.dart';
import 'product_detail_screen.dart';
import '../../data/models/product.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Gris sistema iOS
      body: CustomScrollView(
        slivers: [
          // SliverAppBar colapsable — le da ese feel de la App Store
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: const Color(0xFFF2F2F7),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Tienda',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductCard(
                  product: demoProducts[index],
                ),
                childCount: demoProducts.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

/// Tarjeta de producto con Hero en la imagen
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        _buildPageRoute(product),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Sombra sutil estilo iOS — evita elevation de Material
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HERO: la imagen que vuela hacia el detalle ───────────────
            Hero(
              tag: 'product-image-${product.id}',
              // flightShuttleBuilder no es necesario aquí — el comportamiento
              // por defecto de Hero ya interpola el BorderRadius correctamente
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  product.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Placeholder mientras carga — no dejamos pantalla vacía
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: const Color(0xFFE5E5EA),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
            // ─── Contenido textual ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría — label pequeño arriba
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Nombre del producto — también puede ser Hero para
                  // animar el texto, pero lo mantenemos simple aquí
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3C3C43),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ruta personalizada que se siente premium
/// La combinación Fade + Slide sutil es lo que usa la App Store
PageRouteBuilder _buildPageRoute(Product product) {
  return PageRouteBuilder(
    // transitionDuration más largo que el default (300ms) para que
    // el Hero tenga tiempo de lucirse
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ProductDetailScreen(product: product),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade suave + micro slide hacia arriba — idéntico al estilo App Store
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
```

---

## Pantalla de Detalle

```dart
// lib/features/products/presentation/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import '../../data/models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    // El contenido textual aparece después de que el Hero
    // termine de volar — damos 300ms de delay
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    ));

    // Iniciamos la animación del contenido después del Hero
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ─── Contenido scrollable ────────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── HERO: el mismo tag que en la lista ───────────────────
                Hero(
                  tag: 'product-image-${product.id}',
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    // Imagen más alta en el detalle — la transición
                    // interpolará el tamaño automáticamente
                    height: 380,
                    fit: BoxFit.cover,
                  ),
                ),

                // ─── Contenido textual — aparece con animación propia ─────
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categoría
                          Text(
                            product.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Nombre
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Precio
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3C3C43),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Separador
                          const Divider(color: Color(0xFFE5E5EA)),
                          const SizedBox(height: 20),

                          // Descripción
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Color(0xFF3C3C43),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // CTA
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Agregar al carrito',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Botón de regreso flotante ────────────────────────────────────
          // Posicionado encima de la imagen con fondo semitransparente
          Positioned(
            top: topPadding + 8,
            left: 16,
            child: _BackButton(),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
```

---

## Cómo conectarlo en `main.dart`

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'features/products/presentation/screens/product_list_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Store Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display', // O usa el default
        useMaterial3: true,
      ),
      home: const ProductListScreen(),
    );
  }
}
```

---

## Decisiones clave explicadas

### 1. Por qué usamos `PageRouteBuilder` en lugar de `MaterialPageRoute`

`MaterialPageRoute` usa un slide desde la derecha en Android y una transición de modal en iOS. Ninguna de las dos se siente como la App Store. Con `PageRouteBuilder` controlamos exactamente el fade + micro-slide que Apple usa en sus apps. El `Hero` funciona igual en cualquier tipo de ruta — no está ligado al tipo de transición de pantalla.

### 2. Por qué el `tag` incluye el `id` del producto

Si tuviéramos múltiples productos en la lista con el mismo tag, Flutter entraría en conflicto al intentar animar más de un Hero a la vez. El tag `'product-image-${product.id}'` garantiza unicidad. Si no tienes `id`, usa el índice del ítem o cualquier valor único.

### 3. Por qué el texto del detalle tiene su propia animación con delay

El Hero anima la imagen. Pero el texto en el detalle simplemente "aparece" sin gracia si no lo animamos por separado. Al darle un delay de 300ms (aprox. cuando el Hero termina), hacemos que el contenido textual entre suavemente después — es exactamente lo que hace la App Store cuando abres la ficha de una app.

### 4. Por qué `ClipRRect` va **dentro** del Hero en la lista y no fuera

Si pones el `ClipRRect` fuera del `Hero`, Flutter no puede interpolar el radio de esquinas durante el vuelo — la imagen hará un "flash" o mostrará esquinas raras durante la transición. Al ponerlo dentro, el Hero lo incluye en la animación y puedes ver cómo las esquinas redondeadas se abren suavemente hacia la imagen del detalle (que no tiene clip).

### 5. Por qué no usamos `go_router` aquí

`go_router` con `CustomTransitionPage` funciona igual de bien, pero para esta demo de una sola feature, la complejidad extra no aporta valor. Si ya usas `go_router` en tu proyecto, simplemente envuelve `ProductDetailScreen` en un `CustomTransitionPage` con el mismo `transitionsBuilder` que definimos en `_buildPageRoute`.

---

## Variante con `go_router`

Si ya tienes `go_router` configurado:

```dart
// En tu router
GoRoute(
  path: '/products/:id',
  pageBuilder: (context, state) {
    final product = state.extra as Product;
    return CustomTransitionPage(
      key: state.pageKey,
      child: ProductDetailScreen(product: product),
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  },
),

// Para navegar:
context.push('/products/${product.id}', extra: product);
```

---

## Checklist de implementación

- [ ] Verificar que el `tag` del `Hero` es único por ítem en la lista
- [ ] El widget hijo del `Hero` en lista y detalle deben ser visualmente iguales (mismo widget de imagen)
- [ ] `ClipRRect` dentro del `Hero`, no fuera
- [ ] La ruta usa `PageRouteBuilder` con fade + slide sutil
- [ ] El contenido textual del detalle tiene delay para aparecer después del Hero
- [ ] El botón de regreso es accesible desde la imagen (área segura)
- [ ] Imagen usa `loadingBuilder` para no mostrar contenedor vacío

---

## Resultado

Con esta implementación obtienes:

1. La imagen "vuela" desde la tarjeta de la lista hasta ocupar el ancho completo del detalle
2. El radio de esquinas se interpola suavemente (desaparece en el detalle)
3. El tamaño de imagen se interpola de 200px a 380px durante el vuelo
4. El contenido textual aparece con un fade-in suave después del Hero
5. El comportamiento de regreso (pop) reproduce toda la animación al inverso automáticamente — Flutter lo maneja solo
