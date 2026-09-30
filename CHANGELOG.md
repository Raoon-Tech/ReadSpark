# Changelog

Todo notable de ReadSpark se documenta aquí.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-1.1.0/) y el versionado semántico se definirá en la Fase 10 antes de generar releases (§8 prohíbe releases automáticos sin estrategia de versionado y firma).

## [Unreleased]

### Added

- Documentación de la Fase 0: arquitectura, entorno de desarrollo, dependencias y licencias, requisitos, modelo documental y esquema de base de datos.
- Proyecto Flutter 3.47.5 con plataformas Android y Windows (org `com.raoon.readspark`).
- Estructura de carpetas Clean Architecture (Fase 1) con `core`, `domain`, `data` y `presentation`.
- `ReadSparkApp` con Riverpod (`ProviderScope`) y placeholder de biblioteca.
- Configuración de lint (`flutter_lints` 6.0.0), formatter y primeros tests (smoke + unit).
- Pipeline de CI en reposo (`.github/workflows/ci.yml`): analyze, test y verificación de licencias.
- Persistencia SQLite con Drift 2.35.0 (Fase 2): esquema v1 (7 tablas + 6 índices), 5 DAOs y repositorios de `domain` sobre `AppDatabase` con `PRAGMA foreign_keys = ON`.
- Tests de base de datos en memoria (28 en total): CRUD de documentos, contenido (secciones/párrafos), upsert de progreso 1 fila/documento, cascadas, settings, bookmarks y caché de voces.
- Biblioteca 100% offline (Fase 3): importación con `file_picker` (copia gestionada + registro de metadatos), listado reactivo (`documents LEFT JOIN reading_progress`), secciones Continuar leyendo / Recientes / Favoritos / Todos, búsqueda por título, favoritos, eliminar con confirmación y pantalla de lector provisional.
- Casos de uso `ImportDocument` / `DeleteDocument`, puerto `DocumentFilePort` y proyección `LibraryItem` (ADR-005) con tests unitarios y widget (52 tests en total).
