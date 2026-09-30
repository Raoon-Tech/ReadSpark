# ReadSpark

Aplicación multiplataforma para leer documentos digitales (PDF, DOCX, Markdown, TXT) y escuchar su contenido mediante Text-to-Speech (TTS), con guardado automático de progreso y uso totalmente **offline**.

## Propósito

ReadSpark permite al usuario:

1. Importar documentos desde el sistema de archivos.
2. Verlos y leerlos en una biblioteca personal.
3. Escuchar su contenido con voces disponibles en el dispositivo.
4. Ajustar voz, velocidad y tono.
5. Guardar automáticamente el progreso y continuar exactamente donde lo dejó.
6. Buscar contenido, marcar favoritos y crear marcadores.
7. Funcionar sin conexión a Internet en todas las operaciones principales.

## Plataformas

| Fase | Plataformas |
|---|---|
| MVP | Android, Windows |
| Futuras | Linux, macOS, Web (la arquitectura lo permite; sin soporte explícito en el MVP) |

## Principios fundamentales

- **Offline-first**: importación, biblioteca, lectura, TTS, progreso, favoritos, marcadores y ajustes funcionan sin red. Sin servicios cloud en el MVP.
- **Arquitectura desacoplada**: UI, dominio, persistencia, parsers, TTS, sistema de archivos y plataforma son módulos independientes. El dominio no depende de Flutter, Android ni Windows.
- **Modelo documental común**: todos los formatos se convierten a un modelo interno (`Document` → `DocumentSection` → `DocumentParagraph`). El lector nunca conoce el formato original.
- **Privacidad**: los documentos nunca salen del dispositivo; los logs contienen información técnica, nunca contenido documental.
- **Licencias**: dependencias preferentemente MIT / Apache-2.0 / BSD / ISC, con evidencia registrada en [`docs/dependencies-and-licenses.md`](docs/dependencies-and-licenses.md).

## Stack

- Flutter / Dart (plataforma compartida Android + Windows)
- Clean Architecture + Repository Pattern + Dependency Injection ligero
- Riverpod (gestión de estado)
- SQLite vía Drift (persistencia local, migraciones versionadas)
- pdfrx/PDFium (PDF), archive + xml (DOCX), markdown (MD), stdlib (TXT)
- flutter_tts (TTS con abstracción propia `TtsService`)

## Estructura del repositorio

```text
readspark/
├── android/
├── windows/
├── lib/
│   ├── core/           # constantes, errores, logging, utilidades
│   ├── domain/         # entidades, interfaces de repositorio, casos de uso
│   ├── data/           # base de datos, repositorios, parsers, tts
│   └── presentation/   # pantallas, widgets, estado de UI
├── assets/
├── test/
├── integration_test/
├── docs/
├── scripts/
├── .github/workflows/
├── pubspec.yaml
├── README.md
└── CHANGELOG.md
```

Detalle de las capas en [`docs/architecture.md`](docs/architecture.md).

## Documentación

| Documento | Contenido |
|---|---|
| [docs/architecture.md](docs/architecture.md) | Arquitectura, capas, decisiones (ADRs), ReaderEngine, TTS |
| [docs/development-environment.md](docs/development-environment.md) | Versiones verificadas del entorno |
| [docs/dependencies-and-licenses.md](docs/dependencies-and-licenses.md) | Matriz de dependencias y evidencia de licencias |
| [docs/requirements.md](docs/requirements.md) | Requisitos, casos de uso y criterios de aceptación |
| [docs/document-model.md](docs/document-model.md) | Modelo documental y pipeline por formato |
| [docs/database.md](docs/database.md) | Esquema SQLite, índices y migraciones |

## Estado del proyecto

| Fase | Descripción | Estado |
|---|---|---|
| Fase 0 | Análisis y arquitectura (documentación) | **Completada** |
| Fase 1 | Infraestructura (proyecto Flutter, Git, CI, lint, tests, builds) | **Completada** |
| Fase 2 | Persistencia (SQLite, Drift, migraciones, repositorios) | **Completada** |
| Fase 3 | Biblioteca (importar, listar, buscar, favoritos) | **Completada** |
| Fase 4 | Motor documental (PDF, DOCX, MD, TXT) | **Completada** |
| Fase 5 | Lector visual | Pendiente |
| Fase 6 | TTS | Pendiente |
| Fase 7 | Progreso de lectura | Pendiente |
| Fase 8 | Marcadores y experiencia de lectura | Pendiente |
| Fase 9 | Calidad (tests, rendimiento, accesibilidad, auditoría) | Pendiente |
| Fase 10 | Beta (APK/AAB, instalador Windows, changelog) | Pendiente |
| Fase 11 | Futuras (EPUB, OCR, HTML, IA, etc.) | Fuera del MVP |

## Build

```bash
# Verificar entorno
flutter doctor -v

# Análisis estático y tests (disponibles desde la Fase 1)
flutter analyze
flutter test

# Builds
flutter build apk        # Android
flutter build windows     # Windows
```

Las versiones exactas soportadas están registradas en [`docs/development-environment.md`](docs/development-environment.md).

## Licencia del proyecto

TBD — pendiente de decisión del propietario del proyecto. Las licencias de terceros están documentadas en [`docs/dependencies-and-licenses.md`](docs/dependencies-and-licenses.md).
