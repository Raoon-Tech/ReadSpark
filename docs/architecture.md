# Arquitectura de ReadSpark

Documento de referencia de la arquitectura. Basado en el plan maestro (§3, §4, §18, §32, §36, §42) y las decisiones ADR-001 a ADR-009 tomadas en la Fase 0.

---

## 1. Visión general

```text
                 MVP
                  │
        ┌─────────┴─────────┐
        │                   │
     Android             Windows
        │                   │
        └─────────┬─────────┘
                  │
               Flutter
                  │
       ┌──────────┴──────────┐
       │                     │
 Document Engine          TTS Engine
       │                     │
 PDF/DOCX/MD/TXT          Android/Windows
       │
 DocumentModel (entidades de dominio)
       │
     Reader
       │
   Progress
       │
    SQLite (Drift)
```

Objetivo evolutivo (§42): un **núcleo compartido** (Documents, TTS, Reader, Progress, DB) al que se le pueden añadir plataformas (Linux/macOS/Web), formatos (EPUB/HTML/ODT) y extensiones futuras (nube, IA) sin reescribir el núcleo.

---

## 2. Capas y regla de dependencia

```text
lib/
├── core/           # utilidades transversales sin reglas de negocio
├── domain/         # REGLA DE ORO: no importa Flutter, Android, Windows, data ni UI
├── data/           # implementa interfaces de domain; puede importar domain y core
└── presentation/   # UI Flutter; importa domain (casos de uso) y core; NO data directamente
```

Reglas:

1. `domain` no importa `package:flutter/*`, ni plugins de plataforma, ni `data`, ni `presentation`.
2. `presentation` depende de `domain` (interfaces y casos de uso), nunca de implementaciones concretas de `data`.
3. `data` depende de `domain` (para implementar sus interfaces) y de `core`.
4. La composición (inyección de dependencias) ocurre en un único punto de arranque (`presentation/app`).
5. `core` no conoce reglas de negocio; solo constantes, errores tipados, logging, extensiones y utilidades.

Con esto se cumple §3.2 (desacople), §36 Mantenibilidad (añadir formato = nuevo importer, sin tocar el lector) y §36 Extensibilidad (nueva implementación TTS sin tocar el dominio).

---

## 3. Módulos del dominio (§9 y §10)

```text
domain/
├── documents/    # Document, DocumentSection, DocumentParagraph + DocumentRepository + casos de uso
├── reader/       # ReaderEngine (abstracción), estados, eventos
├── progress/     # ReadingProgress + ProgressRepository
├── voices/       # Voice + TtsService (interfaz) + VoiceRepository
├── bookmarks/    # Bookmark + BookmarkRepository
└── library/      # LibraryItem (read-model), LibraryRepository, favoritos
```

Entidades mínimas (detalle de campos en `document-model.md`):

```text
Document, DocumentSection, DocumentParagraph,
ReadingProgress, Voice, Bookmark, LibraryItem, AppSettings
```

---

## 4. Interfaces clave (ubicación según ADR-002)

### 4.1 TTS — en `domain/voices`

```dart
abstract class TtsService {
  Future<List<Voice>> getVoices();
  Future<void> speak(String text);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> setVoice(Voice voice);
  Future<void> setRate(double rate);
  Future<void> setPitch(double pitch);
  Stream<TtsEvent> get events;
}
```

Implementaciones en `data/tts` (ADR-002):

```text
TtsService
   ├── AndroidTtsService   (flutter_tts, adaptador Android)
   └── WindowsTtsService   (flutter_tts, adaptador Windows)
```

La aplicación (dominio/UI) nunca llama a APIs del sistema operativo directamente. Si `setVoice` no está soportado en una plataforma (riesgo ADR-008), el adaptador de esa plataforma implementa el comportamiento equivalente (p. ej. por locale) sin que el dominio se entere.

### 4.2 Importadores — en `data/parsers`

```dart
abstract class DocumentImporter {
  bool supports(String extension);
  Future<ImportedDocument> importDocument(File file);
}
```

Registro de importadores (ADR-007), sin condicionales gigantes:

```text
ImporterRegistry
   ├── PdfImporter      (pdfrx/PDFium)
   ├── DocxImporter     (archive + xml)
   ├── MarkdownImporter (package:markdown)
   └── TxtImporter      (Dart stdlib)

Posteriormente (Fase 11): EpubImporter, HtmlImporter, OdtImporter
```

Añadir un formato = registrar un importador nuevo. No se modifica el lector, el ReaderEngine ni el TTS.

### 4.3 Repositorios — en `domain/*/repositories`

```text
DocumentRepository    (CRUD, búsqueda, orden, favoritos)
ProgressRepository    (upsert/lectura por documento)
BookmarkRepository
VoiceRepository       (caché de voces del dispositivo)
SettingsRepository    (clave-valor)
```

Las implementaciones viven en `data/repositories` sobre Drift (`data/database`).

---

## 5. Pipeline documental (§3.3 y ADR-001)

```text
PDF ──── pdfrx loadText ──┐
DOCX ─── archive+xml ─────┤
MD ───── markdown AST ────┼──▶ ImporterRegistry ─▶ Document + Sections + Paragraphs
TXT ──── stdlib ──────────┘                              │
                                                         ▼
                                            Presentation (lector visual)
                                                         │
                                                         ▼
                                          ReaderEngine ─▶ TtsService
                                                         │
                                                         ▼
                                                  ReadingProgress ─▶ SQLite
```

- `DocumentModel` **no** es una estructura paralela: es el agregado `Document + DocumentSection[] + DocumentParagraph[]` de las entidades de dominio (ADR-001).
- Ninguna capa de presentación ni de lectura conoce `format` salvo para mostrar el icono/etiqueta.

---

## 6. ReaderEngine (§18)

Abstracción independiente de la UI, en `domain/reader`:

```text
load(document)  play()  pause()  resume()  stop()
nextParagraph() previousParagraph() seek(position) getCurrentPosition()
```

Estados:

```text
idle → loading → ready → playing ⇄ paused
                     │       │
                     ▼       ▼
                  stopped  completed
                     │
                   error
```

Responsabilidades:

- Mantener estado, posición (sección/párrafo/offset), progreso y eventos TTS.
- Segmentar el contenido para TTS (§20): `document → section → paragraph → chunk` (frase/trozo).
- Emitir eventos para que la UI resalte el párrafo actual y actualice controles.
- Guardar progreso automáticamente (Fase 7): upsert en `reading_progress` con `section + paragraph + characterOffset + percentage` (§12).

Los **chunks son de runtime, no se persisten** (ADR-003): la unidad de guardado es el párrafo + offset de carácter, estable entre renderizadores y tamaños de pantalla.

---

## 7. Segmentación TTS (§20)

```text
document
  ↓ (persistido en DB)
section
  ↓ (persistido en DB)
paragraph        ← unidad de guardado de progreso
  ↓ (runtime)
sentence/chunk   ← unidad enviada al TtsService
```

Reglas:

- Nunca enviar el documento completo al TTS.
- Chunks de tamaño razonable (por frase, con límite de caracteres) para permitir reanudar, resaltar, pausar, avanzar y retroceder.
- Procesamiento asíncrono / isolates para documentos largos sin bloquear la UI (§26).

---

## 8. Estado de la aplicación (§4 stack)

- **Riverpod** como única solución de gestión de estado (no mezclar Provider/Bloc/GetX).
- Estado de UI (búsqueda, orden, selección) en providers de presentación.
- Estado del ReaderEngine en un provider que expone `Stream`/`AsyncValue` de eventos.
- Los repositorios se inyectan como providers en el arranque; la UI solo ve casos de uso/interfaces de dominio.

---

## 9. Errores (§29)

- Excepciones técnicas tipadas en `core/errors` (`ParserException`, `ImportException`, `TtsException`, `StorageException`).
- La UI nunca muestra texto técnico: cada error tiene un mensaje de usuario recuperable y un código logueable.
- Los parsers capturan sus propias excepciones y las envuelven con contexto (formato, archivo), sin registrar contenido del documento en logs (§25).

---

## 10. Seguridad (§25)

- Sin subidas a servidores, sin terceros, sin analítica externa (§31).
- Validación de rutas (evitar path traversal), de extensiones y de tipos MIME antes de importar.
- Límites de recursos ante archivos malformados (tamaño máximo, profundidad de parsing, timeouts).
- Logs técnicos solamente: nunca texto de documentos, metadatos privados ni rutas completas del usuario en producción.

---

## 11. Rendimiento (§26 y §36)

- Importación, parsing, búsqueda y persistencia fuera del hilo de UI (isolates cuando aporte).
- Carga progresiva/paginación en el lector para documentos grandes.
- Caching controlado de secciones/párrafos ya parseados.
- Medir antes de optimizar.

---

## 12. Testing (§27)

| Nivel | Cubre |
|---|---|
| Unit | parsers, entidades, casos de uso, progreso, repositorios, segmentación TTS |
| Widget | biblioteca, lector, configuración, controles |
| Integration | importar → abrir → reproducir → guardar progreso → cerrar → reabrir → continuar (flujo crítico §27) |

Documentos de prueba en `test/assets/documents/` (§28): `sample.pdf`, `sample.docx`, `sample.md`, `sample.txt`, `large.pdf`, `large.docx`, `unicode.md`, `long-text.txt` con español, inglés, Unicode, acentos, emojis, listas y títulos.

---

## 13. Decisiones arquitectónicas (ADRs)

### ADR-001 — Un único modelo documental

- **Contexto**: §3.3 define un `DocumentModel` y §10 define entidades; riesgo de duplicación.
- **Decisión**: `DocumentModel` = agregado de las entidades de dominio (`Document` + `DocumentSection[]` + `DocumentParagraph[]`). Los parsers producen entidades de dominio directamente.
- **Consecuencia**: cero conversión extra entre importación y lectura; una sola fuente de verdad.

### ADR-002 — Interfaces en dominio, implementaciones en data

- **Contexto**: `TtsService` (§4) e `DocumentImporter` (§13) podrían vivir en data y contaminar el dominio.
- **Decisión**: las abstracciones de TTS viven en `domain/voices`; las implementaciones (`AndroidTtsService`, `WindowsTtsService`) en `data/tts`. Los importadores se declaran como contrato en data/parsers (son parte de la política de acceso a datos) pero producen entidades de dominio.
- **Consecuencia**: el dominio no depende de Flutter ni del SO; añadir plataforma no toca el dominio.

### ADR-003 — Chunks TTS en runtime, progreso a nivel párrafo

- **Contexto**: §20 menciona `sentence/chunk`, ausente del modelo de §10.
- **Decisión**: los chunks se derivan en runtime del párrafo actual; **no se persisten**. El progreso se guarda como `document + section + paragraph + characterOffset` (+ página auxiliar).
- **Consecuencia**: consistente con §12 (DOCX/MD sin páginas estables); reanudable aunque cambie el renderizador o el tamaño de pantalla.

### ADR-004 — Tabla `voices` como caché de voces del dispositivo

- **Contexto**: §11 incluye tabla `voices`; §19 dice que las voces provienen del dispositivo y que la configuración se guarda por usuario.
- **Decisión**: `voices` almacena la caché de voces detectadas (id, nombre, locale, plataforma). Las preferencias del usuario (`tts_voice_id`, `tts_language`, `tts_rate`, `tts_pitch`) viven en `settings`.
- **Consecuencia**: se puede listar voces sin llamar al SO cada vez y se respeta que Android y Windows tengan voces distintas.

### ADR-005 — Favoritos y biblioteca en la tabla `documents`

- **Contexto**: §22 pide favoritos; §10 incluye `LibraryItem`.
- **Decisión**: `is_favorite` y `added_at` se almacenan en `documents`. `LibraryItem` es un read-model (proyección de `Document` + progreso + metadatos de biblioteca), no una tabla separada.
- **Consecuencia**: sin JOINs complejos para la biblioteca; si luego se necesita orden manual de estantería, se añade columna/migración sin romper nada.

### ADR-006 — `document_id` denormalizado en párrafos

- **Contexto**: `DocumentParagraph` en §10 solo tiene `sectionId`.
- **Decisión**: añadir `document_id` a `document_paragraphs` con índice.
- **Consecuencia**: progreso, búsqueda y paginación por documento sin encadenar JOINs; coste de almacenamiento mínimo.

### ADR-007 — Registro de importadores, no condicionales

- **Contexto**: §13 prohíbe los `if (extension == ...)` gigantes.
- **Decisión**: `ImporterRegistry` con lista de `DocumentImporter`; cada importador expone `supports(extension)`.
- **Consecuencia**: añadir EPUB/HTML/ODT (Fase 11) = registrar una clase nueva.

### ADR-008 — Riesgo de selección de voz en Windows

- **Contexto**: `flutter_tts` documenta `setVoice` como soportado en Android/iOS/macOS; el soporte real en Windows debe verificarse empíricamente.
- **Decisión**: verificar en un spike al iniciar la Fase 6 (o antes). Si Windows no soporta `setVoice`, `WindowsTtsService` implementará selección equivalente (p. ej. por locale/UWP voice id) detrás de la misma interfaz.
- **Consecuencia**: el riesgo está aislado en un adaptador; el dominio no cambia.

### ADR-009 — Git y CI en Fase 1

- **Contexto**: §7/§8 piden Git y GitHub Actions; el repositorio aún no existe.
- **Decisión**: `git init` + estructura de ramas (`main`, `develop`, `feature/*`, `fix/*`, `refactor/*`, `release/*`) al inicio de la Fase 1; CI mínimo (`flutter analyze`, `flutter test`, dependency check, build validation) cuando exista el remoto.
- **Consecuencia**: la documentación de la Fase 0 vive en el directorio de trabajo y se versiona con el primer commit de la Fase 1.

---

## 14. Roadmap de arquitectura (§42)

```text
MVP (Android + Windows)
   → núcleo compartido sólido, local, privado
   → extensiones de formato (EPUB/HTML/ODT) sin tocar el lector
   → plataformas adicionales (Linux/macOS/Web)
   → opcionales posteriores: nube, IA, OCR — solo tras estabilizar el MVP
```
