# rsu_app

La app del conductor consulta TiDB mediante una API HTTPS independiente alojable
en Vercel. Incluye únicamente inicio de sesión, programaciones y detalle.

Configuración y despliegue: [backend/README.md](backend/README.md).

```powershell
flutter run --dart-define=API_BASE_URL=https://TU-PROYECTO.vercel.app/api
```

La URL debe existir y superar la comprobación `/api/health`. Todavía no hay un
despliegue de producción validado. Sin configurar esa URL, no se simula un login.

Aplicación móvil para la gestión de residuos sólidos urbanos.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
