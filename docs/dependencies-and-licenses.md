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
| 2 | `drift` | **2.34.4** *(última vista en pub.dev; `VERSION PENDIENTE DE VERIFICACIÓN` de la última al resolver)* | [pub.dev/packages/drift](https://pub.dev/packages/drift) | **MIT** ✅ [evidencia](https://pub.dev/packages/drift/license) | Capa de persistencia SQLite con migraciones | Android, Windows | Activo | ✅ Sí |
| 3 | `drift_dev` (dev) | **2.35.0** (pub.dev) | [pub.dev/packages/drift_dev](https://pub.dev/packages/drift_dev) | **MIT** ✅ [evidencia](https://pub.dev/packages/drift_dev) | Generador de código de Drift | — (build-time) | Activo | ✅ Sí |
| 4 | `sqlite3` (transitivo de drift) | **3.5.2 / 3.6.0** (pub.dev, sep-2026) | [pub.dev/packages/sqlite3](https://pub.dev/packages/sqlite3) | **MIT** ✅ [evidencia](https://pub.dev/packages/sqlite3/license); binario SQLite = dominio público | Bindings FFI a SQLite | Android, Windows | Activo | ✅ Sí |
| 5 | `sqlite3_flutter_libs` | `VERSION PENDIENTE DE VERIFICACIÓN` (confirmar en pub.dev al instalar) | [pub.dev/packages/sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs) | `REVISIÓN DE LICENCIA REQUERIDA` — verificar en pub.dev al instalar (familia Simon Binder, esperada MIT) | Empaqueta librerías nativas SQLite en el build | Android, Windows | Activo | pendiente |
| 6 | `flutter_tts` | **4.2.5** | [github.com/dlutton/flutter_tts](https://github.com/dlutton/flutter_tts) | **MIT** ✅ [evidencia](https://pub.dev/packages/flutter_tts/license) | Motor TTS nativo (Android + Windows) bajo nuestra abstracción `TtsService` | Android ✅, Windows ⚠️ (riesgo ADR-008 con `setVoice`) | Activo (217 issues abiertos — riesgo de soporte; ver §4) | ✅ Sí |
| 7 | `pdfrx` | **2.6.5** | [github.com/espresso3389/pdfrx](https://github.com/espresso3389/pdfrx) | **MIT** ✅ [evidencia](https://github.com/espresso3389/pdfrx) | Renderizado y **extracción de texto PDF** (`PdfPage.loadText`) | Android ✅, Windows ✅ | Activo | ✅ Sí |
| 8 | `pdfrx_engine` (transitivo) | `VERSION PENDIENTE DE VERIFICACIÓN` (la resuelve `pdfrx`) | [pub.dev/packages/pdfrx_engine](https://pub.dev/packages/pdfrx_engine) | MIT (repo monorepo pdfrx, misma licencia; confirmar versión al resolver) | Motor PDF multiplataforma sin Flutter | Android, Windows | Activo | ✅ Sí |
| 9 | **PDFium** (nativo vía `pdfium_dart`) | `VERSION PENDIENTE DE VERIFICACIÓN` (la resuelve pdfrx) | [chromium/pdfium](https://github.com/chromium/pdfium) | **BSD-3-Clause + Apache-2.0** (doble licencia en LICENSE) ✅ [evidencia](https://pdfium.googlesource.com/pdfium/+/refs/heads/main/LICENSE) | Parser/render PDF nativo | Android, Windows | Activo (Google/Chromium) | ✅ Sí (ambas en allowlist) |
| 10 | `markdown` | **7.3.1** | [github.com/dart-lang/markdown](https://github.com/dart-lang/markdown) | **BSD-3-Clause** ✅ [evidencia](https://pub.dev/packages/markdown/license) | Parser Markdown (dart-lang, oficial) | Todas (puro Dart) | Activo (equipo Dart) | ✅ Sí |
| 11 | `archive` | `VERSION PENDIENTE DE VERIFICACIÓN` (última al instalar) | [github.com/brendan-duncan/archive](https://github.com/brendan-duncan/archive) | **MIT** ✅ [evidencia](https://pub.dev/packages/archive/license) | Descomprimir `.docx` (ZIP) | Todas (puro Dart) | Activo | ✅ Sí |
| 12 | `xml` | `VERSION PENDIENTE DE VERIFICACIÓN` (última al instalar) | [github.com/google/xml.dart](https://github.com/google/xml.dart) | **MIT** ✅ [evidencia: "The MIT License" en pub.dev/packages/xml](https://pub.dev/packages/xml) | Parsear `word/document.xml` del DOCX | Todas (puro Dart) | Activo (Google) | ✅ Sí |
| 13 | `file_picker` | `VERSION PENDIENTE DE VERIFICACIÓN` (12.x/13.x; arquitectura federada desde 12.0) | [github.com/miguelpruivo/flutter_file_picker](https://github.com/miguelpruivo/flutter_file_picker) | **MIT** ✅ [evidencia](https://pub.dev/packages/file_picker/license) (cambió de Apache-2.0 a MIT) | Selector nativo de archivos (importar documentos) | Android ✅, Windows ✅ | Activo | ✅ Sí |
| 14 | `path_provider` | **2.1.6** | [pub.dev/packages/path_provider](https://pub.dev/packages/path_provider) | **BSD-3-Clause** ✅ [evidencia](https://pub.dev/packages/path_provider/license) | Directorios de datos/app en Android y Windows | Android ✅, Windows ✅ | Activo (Flutter team) | ✅ Sí |

**Criterio de inclusión:** todas las entradas con licencia verificada pertenecen a la allowlist (MIT / BSD-3-Clause / Apache-2.0). La única entrada pendiente de verificación (#5) está bloqueada con sello hasta confirmar.

---

## 2. Dependencias de plataforma (toolchain, no pub.dev)

| Componente | Versión verificada | Licencia | Notas |
|---|---|---|---|
| Flutter SDK | 3.47.5 stable | BSD-3-Clause (repositorio flutter/flutter) | Ver `development-environment.md` |
| Android SDK / build-tools | 36.0.0 | Apache-2.0 (Android Open Source) | Solo para builds Android |
| Visual Studio Community 2026 | 18.10.2 | Términos Microsoft (Community, uso individual/equipo pequeño) | Workload C++ para `flutter build windows` — **no** es open source; es toolchain de compilación, no se redistribuye |
| JBR (Android Studio) | 25.0.3 | GPLv2 + Classpath Exception (JetBrains Runtime) | Toolchain de compilación; no se redistribuye con la app |
| SQLite (binario nativo) | la que distribuya `sqlite3` | Dominio público (SQLite) | `sqlite3_flutter_libs` empaqueta el binario — verificar licencia del paquete (entrada #5) |

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
