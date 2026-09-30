# Requisitos de ReadSpark (MVP)

Requisitos, casos de uso y criterios de aceptación del MVP, extraídos del plan maestro (§2, §21–§27, §31, §36, §41). Cada requisito referencia la sección de origen.

---

## 1. Requisitos funcionales

### Biblioteca e importación

| ID | Requisito | Origen |
|---|---|---|
| RF-01 | El usuario puede importar archivos PDF, DOCX, Markdown (.md) y TXT desde el sistema de archivos. | §13, §41.3 |
| RF-02 | La importación registra el documento con título, formato, tamaño, ruta y fechas. | §10 |
| RF-03 | La biblioteca lista documentos con título, formato, porcentaje de lectura, última lectura, icono/portada y estado. | §22 |
| RF-04 | La biblioteca se ordena por: Continuar leyendo / Recientes / Favoritos / Todos. | §22 |
| RF-05 | La biblioteca permite búsqueda por título (y contenido en fases posteriores). | §22 |
| RF-06 | El usuario puede eliminar documentos de la biblioteca (y opcionalmente el archivo original). | §30 Fase 3 |
| RF-07 | El usuario puede marcar/desmarcar favoritos. | §22, §41.16 |

### Lector visual

| ID | Requisito | Origen |
|---|---|---|
| RF-10 | El lector muestra el contenido convertido al modelo común, sin depender del formato original. | §3.3, §30 Fase 5 |
| RF-11 | Navegación por secciones, párrafos y páginas (cuando existan). | §23 |
| RF-12 | Búsqueda de contenido dentro del documento abierto. | §30 Fase 5, §41.7 |
| RF-13 | Ajuste de tamaño de texto/zoom, tema claro/oscuro. | §30 Fase 5 |
| RF-14 | Controles: volver, título, sección actual, ◀ ▶ ▶▶, ▶/⏸, voz, velocidad (1.00x). | §23 |

### Text-to-Speech

| ID | Requisito | Origen |
|---|---|---|
| RF-20 | Listar voces disponibles en el dispositivo (idioma, nombre, proveedor). | §19 |
| RF-21 | Seleccionar voz y persistir la selección por usuario. | §19, §41.9 |
| RF-22 | Ajustar velocidad (rate) y tono (pitch, cuando el motor lo permita). | §19, §41.10 |
| RF-23 | Reproducir, pausar, continuar y detener la lectura por voz. | §19, §41.11–12 |
| RF-24 | Segmentación: nunca enviar el documento completo al TTS; unidad = chunk de párrafo. | §20 |
| RF-25 | Resaltar el párrafo en reproducción y sincronizarlo con la UI. | §20 |
| RF-26 | No asumir que Android y Windows tengan las mismas voces; listar las reales del dispositivo. | §19 |

### Progreso (crítico)

| ID | Requisito | Origen |
|---|---|---|
| RF-30 | Guardar automáticamente: documento, página (auxiliar), sección, párrafo, offset de carácter, porcentaje y fecha/hora. | §12 |
| RF-31 | La identificación principal del progreso es `document + section + paragraph + characterOffset`; la página es auxiliar. | §12 |
| RF-32 | Al reabrir el documento, continuar exactamente donde se dejó (requisito crítico). | §12, §41.14–15 |
| RF-33 | El progreso se conserva aunque cambie el renderizador, el tamaño de pantalla o la UI. | §12 |

### Marcadores y experiencia

| ID | Requisito | Origen |
|---|---|---|
| RF-40 | Crear, listar y eliminar marcadores en la posición actual. | §30 Fase 8 |
| RF-41 | Notas simples asociadas a marcadores. | §30 Fase 8 |
| RF-42 | Historial de lectura (últimos documentos abiertos). | §30 Fase 8 |
| RF-43 | Atajos de teclado en Windows (espacio=pausa, flechas=navegar, etc.). | §30 Fase 8 |

### Configuración y accesibilidad

| ID | Requisito | Origen |
|---|---|---|
| RF-50 | Ajustes persistidos: `tts_voice_id`, `tts_language`, `tts_rate`, `tts_pitch`, tema, tamaño de texto. | §19, §11 |
| RF-51 | Modo oscuro, contraste adecuado, tamaños de texto configurables. | §24 |
| RF-52 | Labels semánticos, soporte básico para lectores de pantalla, navegación por teclado en Windows. | §24 |

### Formatos

| ID | Requisito | Origen |
|---|---|---|
| RF-60 | PDF con texto: extracción de texto, páginas, bloques, navegación. | §14 |
| RF-61 | PDF escaneado (sin texto extraíble): detectar y mostrar "requiere OCR" (OCR fuera del MVP). | §14 |
| RF-62 | DOCX: títulos, subtítulos, párrafos, listas, texto, orden de lectura (estructura semántica, no réplica visual). | §15 |
| RF-63 | MD: títulos, subtítulos, párrafos, listas, enlaces, énfasis, código; por defecto sin ruido sintáctico al escuchar (configurable escuchar código/URLs/símbolos). | §16 |
| RF-64 | TXT: UTF-8, detección de saltos de línea, párrafos, documentos grandes sin cargar todo en memoria si es posible. | §17 |
| RF-65 | Añadir un formato nuevo = registrar un importador; sin modificar el lector. | §36 Mantenibilidad |

### Seguridad y privacidad

| ID | Requisito | Origen |
|---|---|---|
| RF-70 | Sin subidas a servidores, sin envío a terceros, sin analítica externa (offline-first). | §3.1, §25, §31 |
| RF-71 | Los logs nunca contienen contenido documental ni información sensible; solo datos técnicos. | §25 |
| RF-72 | Validar rutas (anti path-traversal), extensiones y tipos; limitar recursos ante archivos malformados; manejar excepciones de parsers. | §25 |
| RF-73 | Los errores mostrados al usuario son mensajes amigables; los códigos técnicos solo en logs. | §29 |

---

## 2. Requisitos no funcionales (§36)

| ID | Categoría | Requisito |
|---|---|---|
| RNF-01 | Rendimiento | La UI no se bloquea durante importación, extracción, parsing, búsqueda ni persistencia. |
| RNF-02 | Disponibilidad | La funcionalidad principal opera 100% offline. |
| RNF-03 | Portabilidad | Máximo código compartido Android/Windows; sin lógica de negocio duplicada por plataforma. |
| RNF-04 | Mantenibilidad | Nuevo formato = nuevo importer sin tocar el lector. |
| RNF-05 | Extensibilidad | Nueva implementación TTS sin modificar el dominio. |
| RNF-06 | Escalabilidad de datos | Documentos grandes manejados razonablemente (carga progresiva, isolates, paginación). |
| RNF-07 | Calidad | `flutter analyze` sin issues, formatter aplicado, tests de lógica crítica en verde (§37). |

---

## 3. Casos de uso

### CU-01 Importar documento
- **Actor:** usuario.
- **Pre:** app abierta, sin red requerida.
- **Flujo:** Importar → seleccionar archivo (file_picker) → validar extensión/ruta → `ImporterRegistry` elige importador → parsear a entidades → guardar en SQLite + registrar en biblioteca.
- **Post:** documento visible en biblioteca con metadatos.
- **Excepciones:** extensión no soportada, archivo corrupto, PDF sin texto (marca `text_extractable=0`), error de lectura → mensaje amigable (RF-73).

### CU-02 Explorar biblioteca
- **Flujo:** listar documentos ordenados (Continuar leyendo / Recientes / Favoritos / Todos) → buscar → ver estado y porcentaje.

### CU-03 Abrir y leer documento
- **Flujo:** seleccionar documento → cargar modelo (secciones/párrafos) → restaurar progreso (RF-32) → leer/scroll/búsqueda interna → navegación por secciones.

### CU-04 Escuchar documento (TTS)
- **Pre:** documento cargado.
- **Flujo:** reproducir → segmentar párrafo → chunk → `TtsService.speak` → resaltar párrafo → guardar progreso en cada avance → pausar/continuar/stop → ajustar voz/velocidad.
- **Post:** progreso persistido; reanudable.

### CU-05 Cambiar voz/velocidad
- **Flujo:** abrir panel de voz → listar voces del dispositivo → seleccionar → ajustar rate/pitch → persistir en `settings`.

### CU-06 Continuar leyendo
- **Flujo:** desde biblioteca, "Continuar leyendo" → abrir documento → posicionar en `section + paragraph + characterOffset` guardados → continuar lectura/escucha.

### CU-07 Marcar favorito / marcador
- **Flujo:** alternar favorito desde biblioteca o lector; crear marcador en posición actual con nota opcional → persistir → listar/eliminar.

### CU-08 Gestionar ajustes
- **Flujo:** cambiar tema, tamaño de texto, opciones TTS → persistir en `settings` → aplicar en reinicio/actual.

---

## 4. Criterios de aceptación del MVP (§41)

Un usuario debe poder:

```text
[ ] 1.  Instalar ReadSpark (Android APK/AAB y Windows installer/package).
[ ] 2.  Abrir la aplicación.
[ ] 3.  Importar un PDF/DOCX/Markdown/TXT.
[ ] 4.  Verlo en su biblioteca.
[ ] 5.  Abrirlo.
[ ] 6.  Leerlo.
[ ] 7.  Buscar contenido.
[ ] 8.  Activar lectura por voz.
[ ] 9.  Elegir una voz disponible en el dispositivo.
[ ] 10. Cambiar velocidad.
[ ] 11. Pausar.
[ ] 12. Continuar.
[ ] 13. Cerrar la aplicación.
[ ] 14. Volver a abrirla.
[ ] 15. Continuar exactamente donde quedó.
[ ] 16. Marcar documentos favoritos.
[ ] 17. Utilizar la aplicación sin Internet.
```

Debe funcionar en **Android** y **Windows**.

### Criterios por fase (§30)

```text
Fase 1: flutter analyze OK · flutter test OK · build Android OK · build Windows OK ✅
Fase 2: CRUD de documentos sin UI definitiva ✅
Fase 3: biblioteca 100% offline ✅
Fase 4: el lector recibe DocumentModel independiente del formato
Fase 5: lectura sin TTS
Fase 6: escuchar documento completo con control de reproducción
Fase 7: abrir → leer → cerrar → reabrir → continuar exactamente
Fase 9: tests unitarios/widget/integración en verde
```

### Flujo de integración crítico (§27)

```text
importar documento → abrir → reproducir → guardar progreso →
cerrar → abrir nuevamente → continuar
```

---

## 5. Fuera del alcance del MVP (§31)

```text
cuentas de usuario · backend · nube · pagos · publicidad · analítica externa ·
sincronización online · IA obligatoria · OCR obligatorio · colaboración · DRM
```

Pantallas MVP (§21): Splash · Biblioteca · Importar documento · Lector · Configuración · Información del documento · Favoritos · Marcadores.
