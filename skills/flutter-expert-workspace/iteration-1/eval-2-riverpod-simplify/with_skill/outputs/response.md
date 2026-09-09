# Simplificando Riverpod en tu pantalla de perfil

## El problema: Riverpod para todo no es arquitectura — es sobreingeniería

Usar Riverpod para manejar si un `TextField` está enfocado es uno de los errores más comunes de quienes vienen aprendiendo state management. El resultado: providers que no aportan valor, boilerplate innecesario, y rebuilds mal controlados.

La pregunta clave antes de crear cualquier provider es: **¿este estado necesita ser compartido fuera de este widget?** Si la respuesta es no, Riverpod no debería estar ahí.

---

## La regla de oro: herramienta correcta para el trabajo correcto

| Tipo de estado | Herramienta |
|----------------|-------------|
| `TextField` enfocado, visible/oculto, tab activo | `setState` en `StatefulWidget` |
| Contador local, toggle simple | `ValueNotifier` + `ValueListenableBuilder` |
| Datos del usuario (nombre, avatar, etc.) desde API | `AsyncNotifierProvider` |
| Sesión de usuario compartida entre pantallas | `StateNotifierProvider` |
| Repositorios y servicios globales | `Provider` |

---

## Antes: El problema en código

```dart
// providers/profile_providers.dart — SOBREINGENIERÍA

// ❌ Provider para si el TextField de nombre está enfocado
final nameFocusedProvider = StateProvider<bool>((ref) => false);

// ❌ Provider para si el TextField de email está enfocado
final emailFocusedProvider = StateProvider<bool>((ref) => false);

// ❌ Provider para si la contraseña es visible
final passwordVisibleProvider = StateProvider<bool>((ref) => false);

// ❌ Provider para el texto del campo de búsqueda local
final searchQueryProvider = StateProvider<String>((ref) => '');

// Este sí tiene sentido:
final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
```

```dart
// profile_screen.dart — con demasiado Riverpod
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameFocused = ref.watch(nameFocusedProvider);    // ❌
    final emailFocused = ref.watch(emailFocusedProvider);  // ❌
    final passwordVisible = ref.watch(passwordVisibleProvider); // ❌
    final userProfile = ref.watch(userProfileProvider);    // ✅

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Nombre',
            border: nameFocused  // ❌ estado local manejado globalmente
                ? OutlineInputBorder(borderSide: BorderSide(color: Colors.blue))
                : OutlineInputBorder(),
          ),
          onTap: () => ref.read(nameFocusedProvider.notifier).state = true,  // ❌
          onEditingComplete: () => ref.read(nameFocusedProvider.notifier).state = false, // ❌
        ),
        // ...
      ],
    );
  }
}
```

**¿Qué pasa aquí?** Cada vez que el usuario toca un `TextField`, Riverpod dispara una notificación, el provider cambia de estado, y todo widget que escucha ese provider se reconstruye. Para algo que Flutter ya maneja nativamente y más eficientemente.

---

## Después: La solución correcta

### Paso 1: Elimina todos los providers de estado local de UI

Borra sin culpa:
- `nameFocusedProvider`
- `emailFocusedProvider`
- `passwordVisibleProvider`
- `searchQueryProvider` (si solo se usa en esta pantalla)

### Paso 2: Convierte la pantalla a StatefulWidget para el estado local

```dart
// profile_screen.dart — CORRECTO
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ✅ Estado local de UI — aquí pertenece
  bool _passwordVisible = false;
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listener en FocusNode para animaciones visuales si las necesitas
    _nameFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // ✅ Siempre limpiar controllers y focus nodes
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Solo Riverpod para lo que realmente es estado global/asíncrono
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      loading: () => const ProfileSkeleton(),
      error: (e, _) => ErrorView(onRetry: () => ref.invalidate(userProfileProvider)),
      data: (user) => _buildProfile(user),
    );
  }

  Widget _buildProfile(UserProfile user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ProfileAvatar(user: user),
          const SizedBox(height: 24),
          _buildNameField(),
          const SizedBox(height: 16),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    final isFocused = _nameFocusNode.hasFocus; // ✅ Nativo, sin providers

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isFocused
            ? [BoxShadow(color: Colors.blue.withOpacity(0.15), blurRadius: 8)]
            : [],
      ),
      child: TextField(
        controller: _nameController,
        focusNode: _nameFocusNode,
        decoration: const InputDecoration(labelText: 'Nombre'),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Email'),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      obscureText: !_passwordVisible, // ✅ Estado local en setState
      decoration: InputDecoration(
        labelText: 'Contraseña',
        suffixIcon: IconButton(
          icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible), // ✅
        ),
      ),
    );
  }
}
```

### Paso 3: El provider de datos del usuario — simplificado también

```dart
// providers/user_profile_provider.dart
// ✅ Solo esto necesita Riverpod en tu pantalla de perfil

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  Future<UserProfile> build() async {
    return ref.watch(userRepositoryProvider).getProfile();
  }

  Future<void> updateName(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).updateName(name),
    );
  }
}
```

---

## Alternativa: ValueNotifier cuando no necesitas ConsumerStatefulWidget

Si tu pantalla ya es `ConsumerWidget` y quieres evitar convertirla a `ConsumerStatefulWidget` solo por un toggle, usa `ValueNotifier`:

```dart
class ProfileScreen extends ConsumerWidget {
  ProfileScreen({super.key});

  // ✅ ValueNotifier — reactivo sin Riverpod, sin setState
  final _passwordVisible = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);

    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _passwordVisible,
          builder: (context, visible, _) {
            return TextField(
              obscureText: !visible,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => _passwordVisible.value = !visible, // ✅
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
```

**Ventaja de `ValueNotifier`:** solo reconstruye el subtree del `ValueListenableBuilder`, no toda la pantalla. Es más quirúrgico que `setState` cuando tienes widgets costosos en el árbol.

---

## El resultado: comparación directa

| Aspecto | Antes (todo Riverpod) | Después (herramienta correcta) |
|---------|----------------------|-------------------------------|
| Providers en el archivo | 4-6 providers | 1 provider (`userProfileProvider`) |
| Boilerplate | Alto | Mínimo |
| Testabilidad del estado de UI | Requiere `ProviderContainer` en tests | Tests de widget estándar |
| Rendimiento | Notificaciones innecesarias | Rebuilds quirúrgicos |
| Legibilidad | Hay que buscar el provider para entender el estado | El estado vive donde se usa |

---

## Checklist para tu pantalla de perfil

Antes de crear cualquier provider, hazte estas preguntas:

- [ ] ¿Otro widget fuera de esta pantalla necesita este estado? Si no → `setState` o `ValueNotifier`
- [ ] ¿Este estado viene de una API o necesita caché? Si sí → `AsyncNotifierProvider`
- [ ] ¿Es una dependencia compartida (repositorio, servicio)? → `Provider`
- [ ] ¿Es solo un toggle, texto local, o foco de campo? → `setState` siempre

---

## Conclusión

Riverpod es una herramienta poderosa — y como toda herramienta poderosa, hacer mal uso de ella tiene un costo. En una pantalla de perfil típica, **un solo `AsyncNotifierProvider`** para los datos del usuario es todo lo que necesitas de Riverpod. El resto — foco de campos, visibilidad de contraseña, estado de edición — vive perfectamente en `StatefulWidget` con `setState` o en `ValueNotifier`.

La arquitectura no es sobre usar la herramienta más avanzada disponible. Es sobre usar la herramienta más simple que resuelve el problema correctamente.
