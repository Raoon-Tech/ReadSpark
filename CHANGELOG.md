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
