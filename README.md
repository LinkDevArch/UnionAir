# UnionAir

Prototipo frontend de búsqueda y reserva de vuelos hecho con Flutter **3.50.1** y Dart **3.14.0**. Las diez pantallas corresponden al [diseño de UnionAir en Figma](https://www.figma.com/design/THsDDkUES4sgdIB1kzRBOU/Untitled).

## Ejecutar

Con Flutter 3.50.1 o una versión estable posterior, abre un emulador o conecta un dispositivo Android. También puedes usar Chrome como destino para revisar la app.

```sh
flutter pub get
flutter run
```

En Chrome, ejecuta `flutter run -d chrome`.

| Campo | Cuenta de demostración |
| --- | --- |
| Correo | `demo@unionair.com` |
| Contraseña | `UnionAir2026` |

La cuenta de demostración incluye un viaje próximo y uno completado. El flujo preselecciona Cali–Bogotá. Para recorrer la reserva de ida y vuelta, elige el vuelo de las 10:10, el regreso de las 17:40, la tarifa Plus y un asiento disponible por trayecto. Completa el pasajero con datos ficticios. La confirmación aparece en **Mis viajes** y puede cancelarse desde el detalle hasta antes de la hora de salida del vuelo de ida, incluso si sale hoy. Si intentas salir de Resultados después de seleccionar un vuelo, la app te pregunta si quieres descartar la reserva en curso.

## Arquitectura y organización

UnionAir usa una arquitectura por capas. `lib/main.dart` crea los servicios y los pasa por constructor a las pantallas. La interfaz maneja el estado de cada pantalla con `StatefulWidget` y `setState`, y comparte un `BookingDraft` durante el flujo de reserva.

- `lib/domain` contiene aeropuertos, consultas, vuelos, pasajeros, tarifas y reservas.
- `lib/data/session_service.dart` gestiona las cuentas de demostración y la sesión.
- `lib/data/flight_service.dart` contiene el catálogo de rutas, horarios y ofertas, y ejecuta la búsqueda.
- `lib/data/booking_service.dart` gestiona las reservas y consulta la ocupación de asientos a partir de las reservas activas. Al reiniciar la app se restablecen los datos de demostración.
- `lib/ui/screens` contiene las pantallas. `lib/ui/design.dart` reúne los componentes y estilos compartidos.
- `assets` contiene las imágenes e iconos de Figma y la tipografía Poppins.

## Navegación

```text
Login
  └─ Buscar
      ├─ Resultados → Tarifa → Asientos → Pasajero → Revisión → Confirmación
      │                                                           ├─ Buscar
      │                                                           └─ Mis viajes
      └─ Mis viajes → Detalle → Constancia simulada / Cancelación
```

## Verificar

```sh
flutter analyze
flutter build web --release --no-web-resources-cdn
```

Consulta las [capturas, decisiones de interfaz y resultados de pruebas](docs/evidencias.md).
