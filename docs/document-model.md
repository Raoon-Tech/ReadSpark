# Modelo documental de ReadSpark

Fuente única de verdad sobre las entidades de documento y el pipeline de importación (§3.3, §10, §13–§17, ADR-001, ADR-003, ADR-005, ADR-006, ADR-007).

---

## 1. Principio

Todos los formatos se convierten a **un único modelo interno**. El lector, el ReaderEngine y el TTS solo consumen este modelo; nunca conocen el formato original.

```text
PDF
DOCX
Markdown
TXT
       │
       ▼
  ImporterRegistry  (data/parsers)
       │
       ▼
  Entidades de dominio: Document + DocumentSection[] + DocumentParagraph[]
       │
       ├── metadata
       ├── chapters/sections
       ├── paragraphs
       └── positions (orden + página auxiliar)
```

`DocumentModel` **no** es una estructura paralela (ADR-001): es el agregado de las entidades de `domain/documents`.

---

## 2. Entidades (§10 + ajustes ADR)

### Document

| Campo | Tipo | Notas |
|---|---|---|
| `id` | String (UUID) | PK |
| `title` | String | nombre base del archivo o título detectado |
| `author` | String? | metadata si existe (p. ej. PDF/DOCX) |
| `format` | enum `pdf \| docx \| markdown \| txt` | para icono/etiqueta; lógica no lo usa |
| `filePath` | String | ruta original accesible para el usuario (§4) |
| `fileSize` | int (bytes) | |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |
| `lastOpenedAt` | DateTime? | orden "Recientes" / índice |
| `totalPages` | int? | auxiliar; `null` en MD/TXT |
| `totalCharacters` | int | base del porcentaje |
| `isFavorite` | bool | ADR-005 (ajuste sobre §10) |
| `addedAt` | DateTime | ADR-005: fecha de alta en biblioteca |
| `textExtractable` | bool | ADR/C7: `false` = PDF escaneado que requiere OCR |

### DocumentSection

| Campo | Tipo | Notas |
|---|---|---|
| `id` | String (UUID) | PK |
| `documentId` | String | FK → Document |
| `title` | String | `""` para sección inicial sin título |
| `order` | int | orden de lectura |
| `level` | int | profundidad jerárquica (0 = raíz, 1..6 = headings) |

### DocumentParagraph

| Campo | Tipo | Notas |
|---|---|---|
| `id` | String (UUID) | PK |
| `documentId` | String | FK → Document (**ajuste ADR-006**) |
| `sectionId` | String | FK → DocumentSection |
| `order` | int | orden dentro de la sección |
| `text` | String | texto ya "limpio" para lectura/TTS |
| `pageNumber` | int? | auxiliar; `null` en MD/TXT |

### ReadingProgress (§12)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | String (UUID) | PK |
| `documentId` | String | **único** (1 fila por documento → upsert) |
| `sectionId` | String? | posición actual |
| `paragraphId` | String? | posición actual |
| `characterOffset` | int | offset dentro del párrafo (identificador principal) |
| `pageNumber` | int? | **dato auxiliar**, nunca identificador |
| `percentage` | double (0–1) | sobre `totalCharacters` |
| `lastReadAt` | DateTime | fecha/hora |

Identificación principal de reanudación: `document + section + paragraph + characterOffset` (§12).

### Voice

| Campo | Tipo | Notas |
|---|---|---|
| `id` | String | id nativo de la voz |
| `name` | String | nombre visible |
| `locale` | String | p. ej. `es-MX`, `en-US` |
| `provider` | String? | proveedor/motor |
| `platform` | enum `android \| windows` | ADR-004: voces distintas por SO |
| `isDefault` | bool | voz por defecto del sistema |
| `lastSyncAt` | DateTime | frescura de la caché |

La selección del usuario (`tts_voice_id`, `tts_language`, `tts_rate`, `tts_pitch`) vive en `Settings`, no en `Voice`.

### Bookmark

| Campo | Tipo | Notas |
|---|---|---|
| `id` | String (UUID) | PK |
| `documentId` | String | FK |
| `sectionId` / `paragraphId` | String | posición exacta |
| `characterOffset` | int | |
| `pageNumber` | int? | auxiliar |
| `note` | String? | nota simple (Fase 8) |
| `createdAt` | DateTime | |

### LibraryItem (read-model, ADR-005)

No es tabla: proyección `Document + ReadingProgress` para la UI de biblioteca,
generada por `LibraryRepositoryImpl` con un `Stream` de
`documents LEFT JOIN reading_progress` (1 fila por documento):

```text
LibraryItem = { document, percentage, lastReadAt, hasProgress }
percentage:  0.0..1.0  (0 si nunca se leyó)
lastReadAt:  DateTime? (null sin fila de progreso)
hasProgress: lastReadAt != null
```

`isFavorite` vive en `document` (columna `documents.is_favorite`, ADR-005);
los estados "nuevo / en curso / completado" se derivan en la UI a partir de
`hasProgress` y `percentage`. La lógica de secciones (Continuar leyendo /
Recientes / Favoritos / Todos) y búsqueda es pura: `applyLibraryView()` en
`presentation/library/library_filter.dart`.

### AppSettings

Clave-valor (ver `database.md`): `tts_voice_id`, `tts_language`, `tts_rate`, `tts_pitch`, `theme`, `font_size_scale`, `speak_code`, `speak_urls`, `speak_symbols`.

---

## 3. Pipeline por formato (§13–§17)

### Registro de importadores (ADR-007)

```dart
abstract interface class DocumentImporter {
  bool supports(String extension);
  Future<ImportedDocument> importDocument(File file, Document base);
}
```

- `base` es el `Document` que crea el caso de uso (id, título, ruta, fechas); el importador devuelve el agregado enriquecido (`copyWith` con autor, páginas, `totalCharacters` calculado y `textExtractable`).
- `ImporterRegistry` (`domain/documents/importers`) resuelve por extensión en minúsculas (`.pdf`, `.docx`, `.md`, `.markdown`, `.txt`). Sin `if/else` encadenados. Fase 11: `EpubImporter`, `HtmlImporter`, `OdtImporter` se registran sin tocar el lector.
- Los importadores construyen secciones/párrafos con `ParsedContentBuilder` (`data/parsers`): ids únicos por documento, sección raíz automática y conteo de caracteres.
- `ImportedDocument` lleva `DocumentContent` + `ImportWarning?` (`scannedPdf`): avisos no bloqueantes que la UI muestra después del éxito (RF-73).

Seguridad de importación (§25): validar extensión permitida, ruta normalizada (sin path traversal), límite de tamaño (**100 MB**, `AppConstants.maxImportSizeBytes`; comprobado antes y después de copiar), y captura de excepciones de parser → `ParserException` con código técnico + mensaje amigable. Ante cualquier fallo la copia gestionada se elimina y no queda registro en la biblioteca.

### PDF (`PdfImporter`) — §14

- Motor: `pdfrx` / `pdfrx_engine` (PDFium), extracción con `PdfPage.loadText` por página; `pdfrxFlutterInitialize()` idempotente antes de abrir.
- Produce: `Document` (con `totalPages`), una `DocumentSection` por capítulo del **outline/bookmarks** (`loadOutline`, niveles 1..6; sin outline → sección raíz única), párrafos con `pageNumber` real (1-based).
- La conversión pura vive en `buildPdfContent` (`pdf_structure_builder.dart`), sin tipos de pdfrx → unit-testable: reparto de párrafos por página, partición en bloques, unión de líneas cortadas por guion.
- **Detección de PDF escaneado (C7):** página "con texto" = ≥10 caracteres extraíbles; si **la mayoría de páginas** no tiene texto → `textExtractable = false` + `ImportWarning.scannedPdf`, mensaje UI: *"Este PDF parece estar escaneado. Requiere OCR (disponible en versiones futuras)."* El documento se importa igualmente con secciones/párrafos vacíos para no perder el registro en biblioteca. **Sin OCR en el MVP** (Fase 11).

### DOCX (`DocxImporter`) — §15

- Descomprimir con `archive` → leer `word/document.xml` (+ `docProps/core.xml` para autor).
- Extraer: títulos/subtítulos (preferentemente `w:outlineLvl`, fallback estilos `Heading1..N` → `level`), párrafos, listas (`w:numPr` → prefijo `• ` en el texto), filas de tabla (una celda-párrafo por celda), texto, orden de lectura (secuencia del documento).
- Objetivo: **estructura semántica para lectura**, no réplica visual del DOCX.
- Sin páginas estables → `pageNumber = null` (por eso el progreso no depende de páginas).

### Markdown (`MarkdownImporter`) — §16

- Parsear con `package:markdown` a AST → headings (`#`..`######`) = `DocumentSection` con `level`, párrafos, listas, enlaces, énfasis, bloques de código.
- Normalización para TTS por defecto: eliminar ruido sintáctico (`` ` ``, `#`, `[]()`, `**`). Opciones de usuario en `AppSettings`: `speak_code`, `speak_urls`, `speak_symbols`.
- Sin páginas → `pageNumber = null`.

### TXT (`TxtImporter`) — §17

- Dart stdlib: detección de codificación UTF-8 (con BOM opcional) y de línea (`\r\n` / `\n` / `\r`).
- Párrafos separados por líneas en blanco; `level = 0` (sin jerarquía); sin páginas.
- Archivos grandes: lectura streaming/progresiva, no cargar todo en memoria si hay alternativa eficiente (§17, §26).

---

## 4. Segmentación para TTS (§20, ADR-003)

```text
document (entidades, persistidas)
   └── section (persistida)
         └── paragraph (persistida)  ← unidad de guardado de progreso
               └── chunk (runtime)   ← unidad enviada al TtsService
```

- Chunks por frase con límite de caracteres; **no se persisten**.
- El progreso dentro de un párrafo se guarda como `characterOffset` = inicio del chunk actual, lo que permite reanudar con precisión sin persistir chunks.
- Ventajas: reanudar, resaltar, pausar, avanzar/retroceder y guardar posición aunque cambie el renderizador (§12).

---

## 5. Convertibilidad y compatibilidad

| Formato | Secciones | Páginas | Listas | Notas |
|---|---|---|---|---|
| PDF | sí (headings detectados) | sí (real) | parcial | escaneado → `textExtractable=false` |
| DOCX | sí (estilos) | no | sí | estructura semántica |
| Markdown | sí (headings) | no | sí | opciones de limpieza TTS |
| TXT | no (nivel raíz) | no | no | más simple; UTF-8 |
| EPUB/HTML/ODT | — | — | — | Fase 11, registrando importers |
