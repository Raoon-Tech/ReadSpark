# Base de datos de ReadSpark

Esquema SQLite gestionado con **Drift** (migraciones versionadas). Conforme a §11 y §12 del plan maestro.

> Regla: **nunca modificar destructivamente el esquema sin una migración versionada.**

---

## 1. Tablas iniciales (v1)

DDL conceptual (Drift genera el SQL real; tipos alineados con SQLite):

```sql
-- documentos
CREATE TABLE documents (
  id              TEXT    PRIMARY KEY,
  title           TEXT    NOT NULL,
  author          TEXT,
  format          TEXT    NOT NULL,          -- 'pdf' | 'docx' | 'markdown' | 'txt'
  file_path       TEXT    NOT NULL UNIQUE,
  file_size       INTEGER NOT NULL,
  created_at      INTEGER NOT NULL,          -- epoch ms
  updated_at      INTEGER NOT NULL,
  last_opened_at  INTEGER,
  total_pages     INTEGER,
  total_characters INTEGER NOT NULL DEFAULT 0,
  is_favorite     INTEGER NOT NULL DEFAULT 0, -- bool (ADR-005)
  added_at        INTEGER NOT NULL,           -- ADR-005
  text_extractable INTEGER NOT NULL DEFAULT 1 -- bool (C7, PDF escaneado)
);
CREATE INDEX idx_documents_last_opened ON documents(last_opened_at);
CREATE INDEX idx_documents_favorite    ON documents(is_favorite);

-- secciones
CREATE TABLE document_sections (
  id           TEXT    PRIMARY KEY,
  document_id  TEXT    NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  title        TEXT    NOT NULL DEFAULT '',
  sort_order   INTEGER NOT NULL,
  level        INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_sections_document ON document_sections(document_id);

-- párrafos
CREATE TABLE document_paragraphs (
  id           TEXT    PRIMARY KEY,
  document_id  TEXT    NOT NULL REFERENCES documents(id) ON DELETE CASCADE, -- ADR-006
  section_id   TEXT    NOT NULL REFERENCES document_sections(id) ON DELETE CASCADE,
  sort_order   INTEGER NOT NULL,
  text         TEXT    NOT NULL,
  page_number  INTEGER                      -- auxiliar; NULL en md/txt/docx
);
CREATE INDEX idx_paragraphs_section  ON document_paragraphs(section_id);
CREATE INDEX idx_paragraphs_document ON document_paragraphs(document_id, sort_order);

-- progreso de lectura (1 fila por documento)
CREATE TABLE reading_progress (
  id              TEXT    PRIMARY KEY,
  document_id     TEXT    NOT NULL UNIQUE REFERENCES documents(id) ON DELETE CASCADE,
  section_id      TEXT    REFERENCES document_sections(id) ON DELETE SET NULL,
  paragraph_id    TEXT    REFERENCES document_paragraphs(id) ON DELETE SET NULL,
  character_offset INTEGER NOT NULL DEFAULT 0,
  page_number     INTEGER,                  -- auxiliar (§12)
  percentage      REAL    NOT NULL DEFAULT 0,
  last_read_at    INTEGER NOT NULL
);
CREATE INDEX idx_progress_document ON reading_progress(document_id);

-- marcadores
CREATE TABLE bookmarks (
  id              TEXT    PRIMARY KEY,
  document_id     TEXT    NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  section_id      TEXT,
  paragraph_id    TEXT,
  character_offset INTEGER NOT NULL DEFAULT 0,
  page_number     INTEGER,
  note            TEXT,
  created_at      INTEGER NOT NULL
);
CREATE INDEX idx_bookmarks_document ON bookmarks(document_id);

-- caché de voces del dispositivo (ADR-004)
CREATE TABLE voices (
  id           TEXT    PRIMARY KEY,          -- id nativo de la voz
  name         TEXT    NOT NULL,
  locale       TEXT    NOT NULL,
  provider     TEXT,
  platform     TEXT    NOT NULL,             -- 'android' | 'windows'
  is_default   INTEGER NOT NULL DEFAULT 0,
  last_sync_at INTEGER NOT NULL
);
CREATE INDEX idx_voices_platform ON voices(platform);

-- ajustes clave-valor
CREATE TABLE settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### Índices exigidos por §11

| Índice | Presente |
|---|---|
| `documents.last_opened_at` | ✅ `idx_documents_last_opened` |
| `reading_progress.document_id` | ✅ `idx_progress_document` (+ `UNIQUE`) |
| `document_sections.document_id` | ✅ `idx_sections_document` |
| `document_paragraphs.section_id` | ✅ `idx_paragraphs_section` |
| `bookmarks.document_id` | ✅ `idx_bookmarks_document` |

Índices adicionales justificados: `document_paragraphs(document_id, sort_order)` (paginación/progreso sin JOINs, ADR-006), `documents(is_favorite)` (vista Favoritos, §22).

---

## 2. Decisiones clave

- **`UNIQUE(document_id)` en `reading_progress`** → el guardado automático es un *upsert*: siempre 1 fila por documento. Sostiene "Continuar leyendo" (§22) y el criterio crítico de la Fase 7.
- **Identificador de reanudación**: `section + paragraph + character_offset` (§12). `page_number` es auxiliar y puede ser `NULL`.
- **`ON DELETE CASCADE`**: eliminar un documento elimina secciones, párrafos, progreso y marcadores.
- **Booleans como INTEGER 0/1** (convención SQLite).
- **Fechas en epoch milliseconds (INTEGER)** — deterministas y comparables.
- **`voices` = caché** del dispositivo (§19 + ADR-004); las preferencias del usuario están en `settings`:
  `tts_voice_id`, `tts_language`, `tts_rate`, `tts_pitch` (§19), más `theme`, `font_size_scale`, `speak_code`, `speak_urls`, `speak_symbols` (§16, §24).

---

## 3. Migraciones (§11)

- Herramienta: **Drift + `drift_dev schema steps`** — snapshots por versión y migraciones generadas/verificadas.
- Toda modificación de esquema = nueva versión + paso de migración; jamás `DROP`/`ALTER` destrutivo sin migración.
- Flujo:

```text
1. Modificar tablas en el código Drift
2. drift_dev schema steps 2 → 3        (genera snapshot + migración)
3. Test de migración desde el snapshot anterior
4. Verificar que los datos existentes sobreviven (sesión de upgrade)
```

- Estado actual: **esquema v1** (este documento). No existen datos en producción hasta la Fase 2.

---

## 4. Ubicación en el código (Fase 2)

```text
lib/data/database/
├── tables/            # definiciones Drift (documents, sections, paragraphs, ...)
├── database.dart      # AppDatabase (schemaVersion, migrations)
├── daos/              # DocumentDao, ProgressDao, BookmarkDao, SettingsDao, VoiceDao
└── connection.dart    # NativeDatabase (Android/Windows), aislamiento de UI
```

- Consultas pesadas y escrituras fuera del hilo de UI (isolate de Drift cuando aplique, §26).
- El acceso desde la UI es **solo** vía repositorios de `domain` implementados en `data/repositories`.

---

## 5. Criterios de aceptación (Fase 2)

```text
crear documento → guardar → consultar → actualizar → eliminar   ✅
upsert de progreso conserva el registro anterior               ✅
migración v1 → v2 sin pérdida de datos                        ✅
índices presentes según §11                                   ✅
```
