# Pantalla de Detalle con Transición Hero en Flutter (estilo App Store de Apple)

## Concepto

La transición que usa la App Store de Apple —donde una tarjeta de la lista se expande suavemente hasta ocupar toda la pantalla— se implementa en Flutter con el widget **`Hero`**. Este widget crea una animación compartida entre dos rutas: la imagen (u otro widget) "vuela" desde su posición en la lista hasta su posición en la pantalla de detalle.

---

## Estructura del proyecto

```
lib/
  models/
    product.dart
  screens/
    product_list_screen.dart
    product_detail_screen.dart
  widgets/
    product_card.dart
  main.dart
```

---

## 1. Modelo de producto

```dart
// lib/models/product.dart

class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
  });
}
```

---

## 2. Pantalla de lista

```dart
// lib/screens/product_list_screen.dart

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  // Datos de ejemplo
  static final List<Product> products = [
    const Product(
      id: 'p1',
      name: 'Auriculares Pro',
      description:
          'Auriculares inalámbricos con cancelación activa de ruido, '
          'hasta 30 h de batería y sonido de alta fidelidad.',
      imageUrl: 'https://picsum.photos/seed/headphones/800/600',
      price: 299.99,
    ),
    const Product(
      id: 'p2',
      name: 'Smartwatch Ultra',
      description:
          'Reloj inteligente con GPS, monitor de frecuencia cardíaca '
          'y resistencia al agua hasta 50 m.',
      imageUrl: 'https://picsum.photos/seed/watch/800/600',
      price: 399.99,
    ),
    const Product(
      id: 'p3',
      name: 'Teclado Mecánico',
      description:
          'Teclado mecánico compacto con switches táctiles, '
          'retroiluminación RGB y conectividad Bluetooth.',
      imageUrl: 'https://picsum.photos/seed/keyboard/800/600',
      price: 149.99,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF2F2F7), // Fondo gris estilo iOS
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
}
```

---

## 3. Tarjeta del producto (con Hero)

El truco está en envolver la imagen con `Hero` y usar un **`heroTag`** único. Ese mismo tag debe usarse en la pantalla de detalle.

```dart
// lib/widgets/product_card.dart

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          // PageRouteBuilder permite personalizar la curva y duración
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 450),
            reverseTransitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (context, animation, secondaryAnimation) {
              return ProductDetailScreen(product: product);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // Fade suave además del Hero
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- HERO: la imagen es el elemento compartido ----
            Hero(
              tag: 'product-image-${product.id}',
              // flightShuttleBuilder opcional para personalizar
              // la apariencia durante el vuelo
              flightShuttleBuilder: (
                flightContext,
                animation,
                flightDirection,
                fromHeroContext,
                toHeroContext,
              ) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(
                        // Interpola el radio: redondo en lista → 0 en detalle
                        Tween<double>(begin: 16, end: 0)
                            .evaluate(animation),
                      ),
                      child: child,
                    );
                  },
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                  ),
                );
              },
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220,
              ),
            ),
            // ---- Información del producto ----
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
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
```

---

## 4. Pantalla de detalle (con Hero)

```dart
// lib/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ---- SliverAppBar con la imagen Hero ----
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                // El tag DEBE ser idéntico al de la tarjeta
                tag: 'product-image-${product.id}',
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),

          // ---- Contenido de la pantalla de detalle ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y precio
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF555555),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botón de compra
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Agregar al carrito'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Punto de entrada (`main.dart`)

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/product_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hero Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // Solo disponible en iOS; en Android usa la fuente del sistema
      ),
      home: const ProductListScreen(),
    );
  }
}
```

---

## Cómo funciona la transición Hero

| Concepto | Explicación |
|---|---|
| **`Hero` widget** | Envuelve el widget que quieres animar. Flutter lo identifica con el `tag`. |
| **`tag` único** | Debe ser idéntico en origen y destino. Usa el ID del producto para evitar colisiones (`'product-image-${product.id}'`). |
| **`flightShuttleBuilder`** | Callback opcional que controla qué se muestra *durante el vuelo*. Aquí se interpola el `borderRadius` de redondeado a 0. |
| **`PageRouteBuilder`** | Permite ajustar `transitionDuration` y agregar un `FadeTransition` adicional sobre el Hero para un efecto más pulido. |
| **`SliverAppBar` + Hero** | La imagen ocupa toda la parte superior en la pantalla de detalle y collapsa al hacer scroll, similar a la App Store. |

---

## Detalles adicionales para un resultado más pulido

### A. Animar también el radio de la tarjeta completa (no solo la imagen)

Si quieres que toda la tarjeta se expanda (no solo la imagen), envuelve el `Container` completo con `Hero`:

```dart
Hero(
  tag: 'product-card-${product.id}',
  child: Material(
    color: Colors.transparent,
    child: Container(
      // ... toda la tarjeta
    ),
  ),
)
```

> **Importante:** cuando el Hero contiene widgets con texto o botones, envuélvelo en `Material` para que los widgets hijos rendericen correctamente durante el vuelo.

### B. Imagen con placeholder mientras carga

```dart
Image.network(
  product.imageUrl,
  fit: BoxFit.cover,
  width: double.infinity,
  height: 220,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
      height: 220,
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator()),
    );
  },
  errorBuilder: (context, error, stackTrace) {
    return Container(
      height: 220,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
    );
  },
)
```

### C. Gesto de "arrastrar hacia abajo para cerrar" (como la App Store)

```dart
// En ProductDetailScreen, reemplaza Scaffold por:
return Scaffold(
  body: GestureDetector(
    onVerticalDragEnd: (details) {
      if (details.primaryVelocity != null &&
          details.primaryVelocity! > 300) {
        Navigator.of(context).pop();
      }
    },
    child: CustomScrollView(...),
  ),
);
```

### D. Usar `cached_network_image` para mejor rendimiento

```yaml
# pubspec.yaml
dependencies:
  cached_network_image: ^3.3.1
```

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: product.imageUrl,
  fit: BoxFit.cover,
  width: double.infinity,
  height: 220,
  placeholder: (context, url) => Container(
    color: Colors.grey.shade200,
    child: const Center(child: CircularProgressIndicator()),
  ),
  errorWidget: (context, url, error) =>
      const Icon(Icons.error, color: Colors.grey),
)
```

---

## Resumen de reglas clave

1. **El `tag` del `Hero` debe ser idéntico** en la lista y en el detalle, y único en toda la pantalla.
2. **Envuelve en `Material`** si el Hero contiene widgets que usan `DefaultTextStyle` o `Theme` para evitar el artefacto visual del texto sin estilo durante el vuelo.
3. **`PageRouteBuilder`** te da control total sobre la duración y la curva de animación de la ruta, complementando la animación Hero.
4. **`flightShuttleBuilder`** es el lugar correcto para interpolar propiedades visuales durante el vuelo (border radius, opacidad, etc.).
5. Para imágenes de red, usa **`cached_network_image`** para que la imagen ya esté en caché cuando se inicia la transición y no haya un flash blanco.
