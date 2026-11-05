# gestor_cafeteria

Cliente Flutter para gestionar los pedidos de una cafetería. Se conecta a la API `mini_backend` por medio de `ApiClient`, que traduce cada respuesta del servidor a un `Failure` tipado. Así la app puede distinguir entre «no encontrado», «conflicto», «datos inválidos», «falla del servidor» y «sin conexión».

## Requisitos

- Flutter con Dart 3.13.2 (probado con Flutter 3.47.2).
- Node.js 22.13 o superior (probado con Node.js 26.7.0).
- Un emulador de Android, Chrome o un celular para ejecutar la app.

## Servidor: mini_backend

`mini_backend` es otro repositorio y no forma parte de este proyecto: https://github.com/DMI-2026/mini_backend

Versión con la que se probó: `0.1.0`, commit [`94d2533`](https://github.com/DMI-2026/mini_backend/commit/94d2533034134e4904dd38df8f2c60d56c2d1d6f).

Para levantarlo, en una carpeta fuera de este proyecto:

```bash
git clone https://github.com/DMI-2026/mini_backend.git
cd mini_backend
node server.js
```

No hace falta `npm install`. Para comprobar que responde, abre http://localhost:8000/health; debe devolver `{"status":"ok"}`.

## Ejecutar la app

Instala las dependencias con `flutter pub get` y elige dónde correrla:

| Dónde | Comando | Dirección del servidor |
|---|---|---|
| Emulador de Android | `flutter run` | `http://10.0.2.2:8000` (automática) |
| Chrome | `flutter run -d chrome` | `http://localhost:8000` (automática) |
| Celular físico | `flutter run --dart-define=API_URL=http://<IP de tu computadora>:8000` | La que indiques en `API_URL` |

En un celular físico, la computadora y el celular deben estar en la misma red. `API_URL` también sirve para apuntar a otro servidor desde cualquier plataforma.

## Pruebas

```bash
flutter test
flutter analyze
```

Las pruebas de `ApiClient` usan `MockClient`, así que no necesitan red ni tener el servidor levantado.

## Estructura

```text
lib/
  main.dart                  Punto de entrada y pantalla de prueba
  core/
    failure.dart             Jerarquía de fallos
    http_client.dart         ApiClient: peticiones y mapeo de errores HTTP
test/
  core/
    failure_test.dart        Pruebas de la jerarquía de fallos
    http_client_test.dart    Pruebas de ApiClient con MockClient
android/, web/               Archivos de cada plataforma
```
