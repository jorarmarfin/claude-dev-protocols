# Simplificando el uso de Riverpod en Flutter: No todo necesita un Provider

## El problema: sobre-ingeniería con Riverpod

Usar Riverpod para **absolutamente todo** — incluyendo si un `TextField` está enfocado — es un error común pero costoso. Crea código verboso, difícil de mantener, y con overhead innecesario de reconstrucciones de widgets.

La regla de oro es:

> **Riverpod es para estado global/compartido o lógica de negocio. El estado local y efímero va en el widget con `StatefulWidget` o herramientas locales.**

---

## Clasificación del estado: ¿Qué va dónde?

| Tipo de estado | Ejemplos | Herramienta correcta |
|---|---|---|
| Estado efímero/local de UI | foco de campo, hover, animación, visibilidad de contraseña | `StatefulWidget` + variables locales |
| Estado de formulario | valores de campos, validación | `TextEditingController`, `GlobalKey<FormState>` |
| Estado de pantalla moderado | tab seleccionado, expansión de panel | `StatefulWidget` o `StateProvider` local con `.autoDispose` |
| Estado global/compartido | usuario autenticado, carrito, tema | Riverpod (`StateNotifierProvider`, `AsyncNotifierProvider`) |
| Datos asincrónicos | perfil de usuario desde API | Riverpod (`FutureProvider`, `AsyncNotifierProvider`) |

---

## Caso de estudio: Pantalla de perfil

### Versión sobre-ingeniada (MAL):

```dart
// providers.dart — ¡Esto es excesivo!
final firstNameFocusedProvider = StateProvider<bool>((ref) => false);
final lastNameFocusedProvider = StateProvider<bool>((ref) => false);
final emailFocusedProvider = StateProvider<bool>((ref) => false);
final isPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final firstNameProvider = StateProvider<String>((ref) => '');
final lastNameProvider = StateProvider<String>((ref) => '');

// profile_page.dart
class ProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirstNameFocused = ref.watch(firstNameFocusedProvider);
    final isPasswordVisible = ref.watch(isPasswordVisibleProvider);
    // ... decenas de ref.watch() para cosas triviales
    
    return TextField(
      onChanged: (val) => ref.read(firstNameProvider.notifier).state = val,
      decoration: InputDecoration(
        labelText: isFirstNameFocused ? 'Nombre *' : 'Nombre',
      ),
    );
  }
}
```

**Problemas:**
- Cada pulsación de tecla dispara notificaciones globales
- Los providers no se limpian automáticamente (memory leaks si no se usa `.autoDispose`)
- El código es imposible de leer
- Rompe la encapsulación: estado de UI expuesto globalmente

---

### Versión simplificada y correcta (BIEN):

```dart
// user_profile_provider.dart — Solo lo que NECESITA ser global
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estado del perfil del usuario (esto SÍ es negocio/global)
@immutable
class UserProfileState {
  final String displayName;
  final String email;
  final String avatarUrl;
  final bool isLoading;
  final String? errorMessage;

  const UserProfileState({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    this.isLoading = false,
    this.errorMessage,
  });

  UserProfileState copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserProfileState(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfileState> {
  @override
  Future<UserProfileState> build() async {
    // Carga inicial del perfil desde el repositorio
    final repo = ref.read(userRepositoryProvider);
    final user = await repo.getCurrentUser();
    return UserProfileState(
      displayName: user.displayName,
      email: user.email,
      avatarUrl: user.avatarUrl,
    );
  }

  Future<void> updateProfile({
    required String displayName,
    required String email,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final updated = await repo.updateProfile(
        displayName: displayName,
        email: email,
      );
      return UserProfileState(
        displayName: updated.displayName,
        email: updated.email,
        avatarUrl: updated.avatarUrl,
      );
    });
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileState>(
  UserProfileNotifier.new,
);
```

```dart
// profile_page.dart — Estado local de UI en StatefulWidget
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // Estado local de UI — ¡aquí, no en Riverpod!
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _emailFocusNode;
  bool _isPasswordVisible = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _nameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();

    // Escuchar cambios para detectar ediciones no guardadas
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    // IMPORTANTE: siempre limpiar controllers y focus nodes
    _nameController.dispose();
    _emailController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(userProfileProvider.notifier).updateProfile(
      displayName: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (mounted) {
      setState(() => _hasUnsavedChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solo observamos el estado GLOBAL del perfil con Riverpod
    final profileAsync = ref.watch(userProfileProvider);

    // Sincronizar controllers cuando llegan los datos iniciales
    ref.listen(userProfileProvider, (previous, next) {
      if (next is AsyncData && previous is! AsyncData) {
        _nameController.text = next.value!.displayName;
        _emailController.text = next.value!.email;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (_hasUnsavedChanges)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Guardar'),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (profile) => _buildForm(profile),
      ),
    );
  }

  Widget _buildForm(UserProfileState profile) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileAvatar(avatarUrl: profile.avatarUrl),
          const SizedBox(height: 24),
          
          // El foco se maneja con FocusNode LOCAL, no con Riverpod
          TextFormField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (val) =>
                val == null || val.isEmpty ? 'El nombre es requerido' : null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'El email es requerido';
              if (!val.contains('@')) return 'Email inválido';
              return null;
            },
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          
          // Visibilidad de contraseña: estado local con setState
          TextFormField(
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  // setState local, ¡no un provider!
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pequeño y puro — no necesita Riverpod
class _ProfileAvatar extends StatelessWidget {
  final String avatarUrl;
  const _ProfileAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton.small(
              onPressed: () {/* lógica para cambiar avatar */},
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Reglas prácticas para decidir qué herramienta usar

### Usa `setState` / `StatefulWidget` cuando:
- El estado solo importa dentro de ese widget (o sus hijos directos)
- El estado es efímero: foco, hover, animaciones, visibilidad
- No necesitas persistir ni compartir el estado entre rutas

### Usa `TextEditingController` y `FocusNode` cuando:
- Manejas campos de texto con lógica de formulario
- Necesitas controlar el foco programáticamente
- Son objetos que requieren `dispose()` — Riverpod no te ayuda con eso de forma natural

### Usa Riverpod cuando:
- El estado se comparte entre múltiples widgets/pantallas
- Necesitas inyectar dependencias (repositorios, servicios)
- El estado sobrevive la navegación
- Tienes operaciones asíncronas (fetch, cache)
- Necesitas reactividad entre partes distantes de la app

---

## Patrón recomendado: "Riverpod para negocio, setState para UI"

```
Pantalla de Perfil
├── ConsumerStatefulWidget  (coordina negocio + UI)
│   ├── ref.watch(userProfileProvider)   ← datos del servidor [Riverpod]
│   ├── TextEditingController            ← valor de campos [local]
│   ├── FocusNode                        ← foco de campos [local]
│   ├── bool _isPasswordVisible          ← visibilidad [local setState]
│   └── bool _hasUnsavedChanges          ← indicador de cambios [local setState]
│
└── userProfileProvider (AsyncNotifier)  ← lógica de negocio [Riverpod]
    ├── build() → carga perfil desde API
    └── updateProfile() → guarda cambios
```

---

## Beneficios de esta simplificación

1. **Menos rebuilds**: `setState` solo reconstruye el widget afectado; un `StateProvider` global puede reconstruir toda la pantalla.
2. **Menos boilerplate**: Eliminas decenas de providers triviales.
3. **Mejor encapsulación**: El estado de UI no contamina la capa de negocio.
4. **Dispose automático**: `StatefulWidget` hace `dispose()` de controllers y focus nodes; con providers globales debes recordar usar `.autoDispose`.
5. **Testing más simple**: La lógica de negocio en `AsyncNotifier` se prueba aislada; el estado de UI no necesita tests unitarios complejos.

---

## Resumen

No existe una sola herramienta para todo en Flutter. La arquitectura correcta es la que usa **la herramienta más simple que resuelve el problema**:

- `setState` para estado efímero de UI
- `TextEditingController` / `FocusNode` para formularios
- Riverpod para estado global, compartido o asíncrono

Usar Riverpod para el foco de un `TextField` no es "más profesional" — es sobre-ingeniería que dificulta el mantenimiento y degrada el rendimiento.
