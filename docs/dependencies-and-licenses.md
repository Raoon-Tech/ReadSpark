# Dependencias y licencias de ReadSpark

Registro de dependencias conforme a §3.4, §33, §39 y §40 del plan maestro.

**Política de licencias permitidas (allowlist):** MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC.
Cualquier licencia fuera de la allowlist → sello **`REVISIÓN DE LICENCIA REQUERIDA`** y detener su incorporación hasta determinar compatibilidad.
Cualquier versión no verificada → sello **`VERSION PENDIENTE DE VERIFICACIÓN`** (nunca inventar versiones).

**Regla de los 10 pasos (§33) antes de incorporar una dependencia:**
1. Identificar el problema que resuelve. 2. Buscar solución en Flutter/Dart. 3. Revisar licencia. 4. Revisar mantenimiento. 5. Compatibilidad Android. 6. Compatibilidad Windows. 7. Tamaño e impacto. 8. Vulnerabilidades conocidas. 9. Registrar aquí. 10. Solo entonces incorporarla.

**Evidencia:** las licencias marcadas ✅ fueron verificadas leyendo la página oficial de licencia (URL indicada) el 29-sep-2026.

---

## 1. Dependencias candidatas aprobadas

| # | Nombre | Versión | Repositorio | Licencia (evidencia) | Uso | Plataformas | Mantenimiento | Compat. comercial |
|---|---|---|---|---|---|---|---|---|
| 1 | `flutter_riverpod` | **3.4.3** | [pub.dev/packages/flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | **MIT** ✅ [evidencia](https://pub.dev/packages/flutter_riverpod/license) | Gestión de estado (única solución, §4) | Android, Windows | Activo (18 días desde última publicación) | ✅ Sí |
| 2 | `drift` | **2.35.0** (resuelta en `pubspec.lock`) | [pub.dev/packages/drift](https://pub.dev/packages/drift) | **MIT** ✅ [evidencia](https://pub.dev/packages/drift/license) | Capa de persistencia SQLite con migraciones | Android, Windows | Activo | ✅ Sí |
| 3 | `drift_dev` (dev) | **2.35.0** (resuelta en `pubspec.lock`) | [pub.dev/packages/drift_dev](https://pub.dev/packages/drift_dev) | **MIT** ✅ [evidencia](https://pub.dev/packages/drift_dev) | Generador de código de Drift | — (build-time) | Activo | ✅ Sí |
| 4 | `sqlite3` (transitivo de drift) | **3.5.2** (resuelta en `pubspec.lock`) | [pub.dev/packages/sqlite3](https://pub.dev/packages/sqlite3) | **MIT** ✅ [evidencia](https://pub.dev/packages/sqlite3/license); binario SQLite = dominio público | Bindings FFI a SQLite; **3.x empaqueta binarios precompilados** para Android y Windows (README oficial) | Android, Windows | Activo | ✅ Sí |
| 5 | `flutter_tts` | **4.2.5** | [github.com/dlutton/flutter_tts](https://github.com/dlutton/flutter_tts) | **MIT** ✅ [evidencia](https://pub.dev/packages/flutter_tts/license) | Motor TTS nativo (Android + Windows) bajo nuestra abstracción `TtsService` | Android ✅, Windows ⚠️ (riesgo ADR-008 con `setVoice`) | Activo (217 issues abiertos — riesgo de soporte; ver §4) | ✅ Sí |
| 6 | `pdfrx` | **2.6.5** (resuelta en `pubspec.lock`) | [github.com/espresso3389/pdfrx](https://github.com/espresso3389/pdfrx) | **MIT** ✅ [evidencia](https://pub.dev/packages/pdfrx/license) | Renderizado y **extracción de texto PDF** (`PdfPage.loadText`) | Android ✅, Windows ✅ | Activo | ✅ Sí |
| 7 | `pdfrx_engine` (transitiva) | **0.6.1** (resuelta en `pubspec.lock`) | [pub.dev/packages/pdfrx_engine](https://pub.dev/packages/pdfrx_engine) | **MIT** ✅ (LICENSE en caché: "The MIT License") | Motor PDF multiplataforma sin Flutter | Android, Windows | Activo | ✅ Sí |
| 8 | **PDFium** (nativo vía `pdfium_dart`/`pdfium_flutter`) | **0.3.1** (resuelta en `pubspec.lock`) | [chromium/pdfium](https://github.com/chromium/pdfium) | **BSD-3-Clause + Apache-2.0** (doble licencia en LICENSE) ✅ [evidencia](https://pdfium.googlesource.com/pdfium/+/refs/heads/main/LICENSE); bindings `pdfium_dart`/`pdfium_flutter` = **MIT** ✅ (LICENSE en caché) | Parser/render PDF nativo | Android, Windows | Activo (Google/Chromium) | ✅ Sí (ambas en allowlist) |
| 9 | `markdown` | **7.3.1** (resuelta en `pubspec.lock`) | [github.com/dart-lang/markdown](https://github.com/dart-lang/markdown) | **BSD-3-Clause** ✅ [evidencia](https://pub.dev/packages/markdown/license) | Parser Markdown (dart-lang, oficial) | Todas (puro Dart) | Activo (equipo Dart) | ✅ Sí |
| 10 | `archive` | **4.3.0** (resuelta en `pubspec.lock`) | [github.com/brendan-duncan/archive](https://github.com/brendan-duncan/archive) | **MIT** ✅ (LICENSE en caché: "Copyright (c) 2013-2021 Brendan Duncan") | Descomprimir `.docx` (ZIP) | Todas (puro Dart) | Activo | ✅ Sí |
| 11 | `xml` | `VERSION PENDIENTE DE VERIFICACIÓN` (última al instalar) | [github.com/google/xml.dart](https://github.com/google/xml.dart) | **MIT** ✅ [evidencia: "The MIT License" en pub.dev/packages/xml](https://pub.dev/packages/xml) | Parsear `word/document.xml` del DOCX | Todas (puro Dart) | Activo (Google) | ✅ Sí |
| 12 | `file_picker` | **13.1.0** (resuelta en `pubspec.lock`) | [github.com/miguelpruivo/flutter_file_picker](https://github.com/miguelpruivo/flutter_file_picker) | **MIT** ✅ [evidencia](https://pub.dev/packages/file_picker/license) (cambió de Apache-2.0 a MIT) | Selector nativo de archivos (importar documentos) | Android ✅, Windows ✅ | Activo | ✅ Sí |
| 13 | `path_provider` | **2.1.6** (resuelta en `pubspec.lock`) | [pub.dev/packages/path_provider](https://pub.dev/packages/path_provider) | **BSD-3-Clause** ✅ [evidencia](https://pub.dev/packages/path_provider/license) | Directorios de datos/app en Android y Windows | Android ✅, Windows ✅ | Activo (Flutter team) | ✅ Sí |

**Criterio de inclusión:** todas las entradas con licencia verificada pertenecen a la allowlist (MIT / BSD-3-Clause / Apache-2.0). Las entradas con sello `VERSION PENDIENTE DE VERIFICACIÓN` se confirmarán en `pubspec.lock` al instalarlas (Fase 3+).

### 1.1 Dependencias instaladas en la Fase 1 (resueltas en `pubspec.lock`)

Licencias verificadas leyendo el archivo `LICENSE` de la caché local de pub (`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev`, 29-sep-2026):

| Nombre | Versión resuelta | Tipo | Licencia (evidencia local) | Uso |
|---|---|---|---|---|
| `flutter_riverpod` | **3.4.3** | directa | **MIT** ✅ (LICENSE en caché: "Remi Rousselet") | Contenedor de providers (`ProviderScope`) |
| `riverpod` | **3.4.3** | transitiva | **MIT** ✅ (LICENSE en caché) | Núcleo de Riverpod |
| `flutter_lints` | **6.0.0** | dev | **BSD-3-Clause** ✅ (LICENSE en caché: "The Flutter Authors", cláusula de redistribución BSD) | Reglas de `analysis_options.yaml` |
| `cupertino_icons` | **1.0.9** | directa | **MIT** ✅ (LICENSE en caché: "Vladimir Kharlampidi") | Iconos iOS-style (plantilla Flutter) |

### 1.2 Dependencias instaladas en la Fase 2 (resueltas en `pubspec.lock`)

Licencias verificadas leyendo el archivo `LICENSE` de la caché local de pub (`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev`, 29-sep-2026):

| Nombre | Versión resuelta | Tipo | Licencia (evidencia local) | Uso |
|---|---|---|---|---|
| `drift` | **2.35.0** | directa | **MIT** ✅ (LICENSE en caché: "MIT License") | Capa SQLite (tablas, DAOs, migraciones) |
| `drift_dev` | **2.35.0** | dev | **MIT** ✅ (LICENSE en caché) | Generador `build_runner` de Drift |
| `build_runner` | **2.16.1** | dev | **BSD-3-Clause** ✅ (LICENSE en caché: "Copyright 2016, the Dart project authors" + cláusulas de redistribución BSD) | Orquestador de generación de código |
| `sqlite3` | **3.5.2** | transitiva | **MIT** ✅ (LICENSE en caché); binarios SQLite precompilados = dominio público | Bindings FFI (Android y Windows incluidos) |
| `sqlparser` | **0.45.0** | transitiva | **MIT** ✅ (LICENSE en caché) | Parser SQL usado por `drift_dev` |

Verificación automatizada en CI: el paso *Dependency license check* de `.github/workflows/ci.yml` recorre `pubspec.lock` y falla si algún paquete alojado contiene licencias GPL/LGPL/MPL fuera de la allowlist.

### 1.3 Dependencias instaladas en la Fase 3 (resueltas en `pubspec.lock`)

Licencias verificadas leyendo el archivo `LICENSE` de la caché local de pub (`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev`, 29-sep-2026):

| Nombre | Versión resuelta | Tipo | Licencia (evidencia local) | Uso |
|---|---|---|---|---|
| `file_picker` | **13.1.0** | directa | **MIT** ✅ (LICENSE en caché: "MIT License") | Selector nativo de archivos para importar (RF-01) |
| `path_provider` | **2.1.6** | directa | **BSD-3-Clause** ✅ (LICENSE en caché: "Copyright 2013 The Flutter Authors") | Carpeta de almacenamiento de la app (copias + BD) |
| `path` | **1.9.1** | directa | **BSD-3-Clause** ✅ (LICENSE en caché: "Copyright 2014, the Dart project authors") | Manipulación segura de rutas (anti path-traversal, RF-72) |
| `windows_file_picker` | **2.0.0** | transitiva | **MIT** ✅ (LICENSE en caché) | Implementación Windows de `file_picker` |
| `xml` | **7.0.1** | transitiva | **MIT** ✅ (LICENSE en caché: "The MIT License") | Se resolvió al instalar `file_picker`; usada en Fase 4 (DOCX) |

### 1.4 Dependencias instaladas en la Fase 4 (resueltas en `pubspec.lock`)

Licencias verificadas leyendo el archivo `LICENSE` de la caché local de pub (`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev`, 30-sep-2026):

| Nombre | Versión resuelta | Tipo | Licencia (evidencia local) | Uso |
|---|---|---|---|---|
| `pdfrx` | **2.6.5** | directa | **MIT** ✅ (LICENSE en caché: "The MIT License") | Extracción de texto y outline de PDF (Fase 4) |
| `markdown` | **7.3.1** | directa | **BSD-3-Clause** ✅ (LICENSE en caché: "Copyright 2012, the Dart project authors") | Parser Markdown → AST (Fase 4) |
| `archive` | **4.3.0** | directa | **MIT** ✅ (LICENSE en caché: "Copyright (c) 2013-2021 Brendan Duncan") | Descompresión ZIP de `.docx` (Fase 4) |
| `xml` | **7.1.0** | directa (era transitiva) | **MIT** ✅ (LICENSE en caché: "Copyright (c) 2006-2026 Lukas Renggli") | Parseo de `word/document.xml` (Fase 4) |
| `pdfrx_engine` | **0.6.1** | transitiva | **MIT** ✅ (LICENSE en caché) | Motor PDF independiente de Flutter |
| `pdfium_dart` | **0.3.1** | transitiva | **MIT** ✅ (LICENSE en caché) | Bindings FFI de PDFium |
| `pdfium_flutter` | **0.3.1** | transitiva | **MIT** ✅ (LICENSE en caché) | Integración PDFium con Flutter (assets/temp) |
| `url_launcher` | **6.3.2** | transitiva | **BSD-3-Clause** ✅ (LICENSE en caché: "Copyright 2013 The Flutter Authors") | Requerida por pdfrx (enlaces externos) |
| `rxdart` | **0.28.0** | transitiva | **Apache-2.0** ✅ (LICENSE en caché) | Requerida por pdfrx (streams) |
| `synchronized` | **3.4.2** | transitiva | **MIT** ✅ (LICENSE en caché: "Copyright (c) 2016, Alexandre Roux Tekartik") | Requerida por pdfrx |
| `posix` | **6.5.2** | transitiva | **MIT** ✅ (LICENSE en caché: "Copyright (c) 2020 Brett Sutton") | Worker nativo de pdfrx |
| `petitparser` | **7.1.0** | transitiva (7.0.2 → 7.1.0) | **MIT** ✅ (LICENSE en caché: "Copyright (c) 2006-2026 Lukas Renggli") | Parser base de `xml` |

---

## 2. Dependencias de plataforma (toolchain, no pub.dev)

| Componente | Versión verificada | Licencia | Notas |
|---|---|---|---|
| Flutter SDK | 3.47.5 stable | BSD-3-Clause (repositorio flutter/flutter) | Ver `development-environment.md` |
| Android SDK / build-tools | 36.0.0 | Apache-2.0 (Android Open Source) | Solo para builds Android |
| Visual Studio Community 2026 | 18.10.2 | Términos Microsoft (Community, uso individual/equipo pequeño) | Workload C++ para `flutter build windows` — **no** es open source; es toolchain de compilación, no se redistribuye |
| JBR (Android Studio) | 25.0.3 | GPLv2 + Classpath Exception (JetBrains Runtime) | Toolchain de compilación; no se redistribuye con la app |
| SQLite (binario nativo) | la que distribuya `sqlite3` 3.5.2 (precompilados incluidos en el paquete) | Dominio público (SQLite) | Verificado: `sqlite3` 3.x empaqueta binarios para Android y Windows (se sustituyó a `sqlite3_flutter_libs`, ver §3) |

---

## 3. Candidatos evaluados y descartados

| Candidato | Motivo del descarte |
|---|---|
| `syncfusion_flutter_pdf` | **Licencia propietaria** (Community License de Syncfusion, no open source). Fuerza registro; incompatible con §3.4. |
| `docx_to_text` | Solo extrae texto plano: pierde títulos, listas y orden semántico (§15 exige conservar estructura). Solución: parser propio con `archive` + `xml`. |
| `doc_text_extractor` | Depende de `syncfusion_flutter_pdf` (licencia propietaria) y de red (`http`) — incompatible con offline-first (§3.1). |
| `pdf_text_extraction` (xpdf) | Binarios solo Linux/Windows (sin Android) y fork de xpdf con licencia no verificada. |
| `printing` / `pdf_render` | No aportan extracción de texto estructurada mejor que pdfrx; dependencia extra innecesaria (§33 paso 2). |
| `shared_preferences` | Innecesario: la configuración vive en la tabla `settings` de SQLite/Drift (§11). Menos dependencias, una sola fuente de verdad. |
| `flutter_tts_no_windows` | Fork innecesario; el riesgo de Windows se gestiona en `WindowsTtsService` (ADR-008). |
| `sqflite` | Reemplazado por Drift (§4 stack): migraciones versionadas y API reactiva. |
| `sqlite3_flutter_libs` | **Obsoleto**: la versión `0.6.0+eol` declara oficialmente que "no hace nada" y debe eliminarse al usar `package:sqlite3` 3.x (README del paquete, 29-sep-2026). `sqlite3` 3.5.2 ya empaqueta binarios precompilados para Android/Windows. |
| Paquetes de red (`http`, `dio`) | Sin funcionalidad de red en el MVP (§31). |

---

## 4. Riesgos y notas

- **flutter_tts (ADR-008):** `setVoice` está documentado como Android/iOS/macOS; el soporte de selección de voz en Windows debe verificarse en un spike (Fase 6). Interfaz `TtsService` aísla el riesgo. Además tiene 217 issues abiertos: vigilar actualizaciones.
- **PDFium:** el LICENSE de upstream contiene BSD-3-Clause **y** Apache-2.0; ambas están en la allowlist. Confirmar en `THIRD_PARTY_NOTICES` al empacar.
- **`file_picker` 12.0+** migró a arquitectura federada y requiere Flutter ≥3.38/Dart ≥3.10 — compatible con Flutter 3.47.5 ✅.
- **Windows:** verificar tras cada `flutter pub get` que `flutter pub deps` no introduzca licencias fuera de allowlist (automatizar en CI, §8: "dependency checks").

---

## 5. Plantilla de registro (§3.4)

```text
Nombre:
Versión:          (o VERSION PENDIENTE DE VERIFICACIÓN)
Repositorio:
Licencia:         (con URL de evidencia)
Uso:
Plataformas:
Estado de mantenimiento:
Compatibilidad comercial:
```
