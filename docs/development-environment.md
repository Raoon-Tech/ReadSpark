# Entorno de desarrollo de ReadSpark

Versiones **verificadas en la máquina de desarrollo el 29 de sep 2026** mediante `flutter doctor -v` y comandos directos. No se fijan versiones arbitrarias (§6, §39): todo lo siguiente fue comprobado antes de registrarlo.

---

## 1. Hardware

| Recomendación (§5.1) | Equipo actual | Estado |
|---|---|---|
| Windows 11 | Windows 11 (build 26200, 25H2) | ✅ |
| CPU 6+ núcleos | — | a verificar en equipo |
| 16 GB RAM mínimo (32 GB recomendado) | 13.9 GB | ⚠️ por debajo del mínimo recomendado; operativo, pero conviene emulador Android con configuración moderada o dispositivo físico |
| SSD ≥ 100 GB libres | 271 GB libres en C: | ✅ |

---

## 2. Software verificado

| Componente | Versión verificada | Origen / notas |
|---|---|---|
| Flutter | **3.47.5** (channel stable, revisión 6a19cca564, 17-sep-2026) | `C:\Users\Henry\develop\flutter` |
| Dart (incluido con Flutter) | **3.13.4** | con Flutter 3.47.5 |
| DevTools | **2.60.0** | con Flutter 3.47.5 |
| Git | **2.56.0.windows.1** | `C:\Program Files\Git\cmd\git.exe` |
| Android Studio | instalado (con JBR incluido) | `C:\Program Files\Android\Android Studio` |
| JDK usado por Flutter | OpenJDK **25.0.3** (JBR de Android Studio) | detectado automáticamente por Flutter |
| JDK en `PATH` | Java **27** (HotSpot 64-bit) | CLI `java`; no usado por Gradle/Flutter (usa el JBR) |
| Android SDK | **36.0.0** | `C:\Users\Henry\AppData\Local\Android\Sdk` (`ANDROID_HOME` no exportado; Flutter lo detecta vía Android Studio) |
| Plataformas Android | `android-36.1`, `android-37.0` | platforms instaladas |
| Build-tools | **36.0.0** | |
| Android NDK | **28.2.13676358** (r28c) | instalado en Fase 1 con `sdkmanager ndk/28.2.13676358` (lo exige `flutter.ndkVersion` de Flutter 3.47); también está disponible el NDK 30.0.16248370 |
| Android Emulator | **37.1.11.0** (build_id 15917651) | |
| Visual Studio | **Community 2026 18.10.2** (18.10.12217.157) | `C:\Program Files\Microsoft Visual Studio\18\Community` |
| Workload C++ (VC.Tools.x86.x64) | instalado | requerido para `flutter build windows` |
| Windows SDK | **10.0.26100.0** (Windows 11 SDK) | |
| Licencias Android | todas aceptadas | `flutter doctor` |

### Matriz Android verificada con Flutter 3.47 (oficial Flutter)

| Ítem | Valor |
|---|---|
| Java mínimo | 17 (el entorno usa JBR 25, compatible) |
| Kotlin Gradle Plugin | 2.4.0 |
| Android Gradle Plugin | 9.1.0 |
| Gradle | 9.3.1 (mínimo para AGP 9.1.0) |
| `flutter.compileSdkVersion` | API 36 |
| `flutter.targetSdkVersion` | API 36 |
| `flutter.minSdkVersion` | API 24 |

---

## 3. Estado de `flutter doctor -v`

```text
[✓] Flutter (Channel stable, 3.47.5, Microsoft Windows, locale es-MX)
[✓] Windows Version (Windows 11 or higher, 25H2)
[✓] Android toolchain (Android SDK 36.0.0, Java JBR 25.0.3, licencias aceptadas)
[✓] Chrome - develop for the web
[✓] Visual Studio - develop Windows apps (Community 2026 18.10.2, Windows 11 SDK 10.0.26100.0)
[✓] Connected device (Windows desktop disponible)
[✓] Network resources

• No issues found!
```

Dispositivos de build disponibles: `windows-x64` (desktop), `chrome`, `edge`. Para Android: emulador o dispositivo físico con depuración USB activada.

---

## 4. Comandos de verificación

```bash
flutter doctor -v      # diagnóstico completo
flutter --version      # versión Flutter/Dart
dart --version
git --version
java -version          # JDK en PATH (el usado por Gradle es el JBR de Android Studio)
```

---

## 5. Verificaciones de la Fase 1

- [x] `flutter create` genera proyecto con `android` y `windows` (org `com.raoon.readspark`, nombre `readspark`).
- [x] `flutter build apk --debug` completa sin errores → `build\app\outputs\flutter-apk\app-debug.apk`.
- [x] `flutter build windows` completa sin errores → `build\windows\x64\runner\Debug\readspark.exe`.
- [x] `flutter analyze` (0 issues) y `flutter test` (3/3) en verde.
- [ ] Emulador Android arranca y despliega la app (o dispositivo físico) — pendiente manual.
- [x] `git init` con estructura de ramas (§7): `main`, `develop` (creadas); `feature/*`, `fix/*`, `refactor/*`, `release/*` al uso.
- [x] Pipeline de CI (§8) creado en `.github/workflows/ci.yml` — en reposo hasta existir remoto; **remoto creado en Fase 2** (`github.com/Raoon-Tech/ReadSpark`) y rama `feature/phase-2-persistence` fusionada vía PR #1.
- [x] `CHANGELOG.md` inicial creado (semántica Keep a Changelog + CalVer pendiente de definir en Fase 10).

---

## 6. Verificaciones de las Fases 2–3

- [x] **Fase 2** (rama `feature/phase-2-persistence`, fusionada al `develop` vía PR #1): `flutter analyze` 0 issues · `flutter test` 28/28 · APK y EXE construidos. `sqlite3_flutter_libs` descartado (los binarios ya vienen en `sqlite3` 3.5.2).
- [x] **Fase 3** (rama `feature/phase-3-library`): `flutter analyze` 0 issues · `flutter test` 52/52 · APK y EXE construidos. Nuevas deps verificadas: `file_picker` 13.1.0 (MIT), `path_provider` 2.1.6 y `path` 1.9.1 (BSD-3).
- [ ] Verificación manual en emulador/dispositivo — pendiente (compartida con la Fase 1, sin emulador disponible en el entorno).

---

## 7. Notas

- No se modificó la configuración global de Flutter (`flutter config`) más allá de lo que el propio instalador dejó.
- `ANDROID_HOME` y `JAVA_HOME` no están exportados en el shell; Flutter funciona detectando Android Studio. Si Gradle u otros tools los necesitan, documentar su exportación aquí al detectarlo en la Fase 1.
- Si Flutter se actualiza de canal, re-verificar este documento (las versiones de esta tabla son la fuente de verdad del proyecto, §39).
