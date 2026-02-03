# SDKQAiOS

Suite de QA del **Mediastream Platform SDK** para iOS. Replica los casos de prueba del ejemplo Android (SDKQA) para validar el SDK en la plataforma Apple.

---

## Contenido

La app muestra una lista de casos de prueba agrupados en **Audio** y **Video**. Al tocar un caso se abre una pantalla con el reproductor configurado según ese escenario.

### Casos de Audio

| Caso | Descripción |
|------|-------------|
| AOD Simple | VOD de audio (MP3), sin servicio. |
| AOD with Service | Igual que AOD Simple + Control Center / pantalla de bloqueo. |
| Episode | Episodio con carga automática del siguiente. |
| Local Audio | Archivo local del bundle (`sample_audio.mp3`). |
| Local Audio with Service | Local + Control Center / pantalla de bloqueo. |
| Live Audio | Streaming en vivo. |
| Live Audio with Service | Live + Control Center / pantalla de bloqueo. |
| Live Audio DVR | Live con selector de modo: Live, DVR, DVR Start, DVR VOD. |
| Mixed Audio | Selector: Local, Audio Simple, Episode, Live (sin servicio). |
| Mixed Audio with Service | Igual que Mixed + Control Center / pantalla de bloqueo. |

### Casos de Video

| Caso | Descripción |
|------|-------------|
| VOD Simple | VOD de video. |
| Next Episode | Episodio con “Next Episode” y “Next Episode Custom” (cadena de IDs). |
| Local Video | Archivo local del bundle (`sample_video.mp4`). |
| Local Video with Service | Local + PiP + Control Center. |
| Episode | Episodio de video con carga automática del siguiente. |
| Live Video | Streaming en vivo. |
| Live Video DVR | Live con selector: Live, DVR, DVR Start, DVR VOD. |
| Mixed Video | Selector: Local, VOD, Live, Episode (sin PiP). |
| Mixed Video with Service | Igual que Mixed + PiP + Control Center. |
| Reels | Reels (id + playerId, entorno DEV, trackEnable false, showDismissButton, autoplay). |

---

## Diferencias con Android (SDKQA)

### 1. “With Service” (servicios y reproducción en segundo plano)

**Android**

- Los casos “with Service” usan **MediastreamPlayerServiceWithSync**: un **Foreground Service** con notificación y controles en la barra de notificaciones.
- La reproducción sigue cuando la actividad se cierra o la app va a segundo plano.
- Requiere permisos como `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS` (Android 13+), etc.

**iOS**

- No existe el concepto de “servicio en primer plano” como en Android.
- **Audio “with Service”**: se usa **Now Playing / Control Center** (`updatesNowPlayingInfoCenter = true`). El audio sigue en segundo plano y los controles aparecen en Centro de control y pantalla de bloqueo.
- **Video “with Service”**: se usa **Picture in Picture (PiP)** + **Control Center** (`updatesNowPlayingInfoCenter`, `canStartPictureInPictureAutomaticallyFromInline`). El video puede seguir en una ventana flotante al salir de la app.

### 2. Picture in Picture (PiP)

- En iOS, los casos de **video “with Service”** (Local Video with Service, Mixed Video with Service) activan PiP.
- El SDK ya integra `AVPictureInPictureController`; la app solo habilita la config correspondiente.
- **Importante**: PiP suele no funcionar bien en el **simulador**. Conviene probar en **dispositivo real**.

### 3. Permisos y configuración de la app

**Info.plist**

- **`UIBackgroundModes` → `audio`**: necesario para que el **audio** siga reproduciéndose en segundo plano (casos “with Service” de audio). Sin esto, el audio se pausa al minimizar la app.
- Para **video** en segundo plano no se usa un modo de background especial; PiP se encarga de seguir mostrando el contenido.

**Android** (referencia)

- Usa permisos como `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`, etc., y declara el `MediastreamPlayerServiceWithSync` en el manifest.

### 4. Recursos locales

- **Audio Local**: requiere `sample_audio.mp3` en el target (Copy Bundle Resources). Si no está, la opción “Local” se oculta en Mixed Audio.
- **Video Local**: requiere `sample_video.mp4` en el target. Si no está, se muestra un mensaje o se oculta “Local” en Mixed Video.
- En el proyecto ya están incluidos ambos archivos; si faltan, hay que añadirlos al target en Xcode.

### 5. Estructura del código

- **Android**: una **Activity** por caso (p. ej. `VideoVodSimpleActivity`, `ReelActivity`).
- **iOS**: un **ViewController** por caso (p. ej. `VideoVodSimpleViewController`, `VideoReelsViewController`).
- La lista de casos y la navegación están en `ViewController`; los tipos de caso en `TestCase.swift`, alineados con el enum de Android.

---

## Cómo ejecutar

1. **CocoaPods**
   ```bash
   cd SDKQAiOS
   pod install
   ```
2. Abrir **`SDKQAiOS.xcworkspace`** (no el `.xcodeproj`) en Xcode.
3. Seleccionar un simulador o dispositivo y pulsar Run.

---

## Dependencias

- **MediastreamPlatformSDKxC** (CocoaPods), versión indicada en el `Podfile`.
- iOS: versión mínima definida en el proyecto (revisar en Xcode).

---

## Estructura del proyecto (resumen)

```
SDKQAiOS/
├── SDKQAiOS/
│   ├── SDKQAiOS/
│   │   ├── ViewController.swift       # Lista de casos y navegación
│   │   ├── TestCase.swift             # Modelo y lista de casos (Audio / Video)
│   │   ├── CaseDetailViewController.swift
│   │   ├── Audio*.swift               # Pantallas de audio
│   │   ├── Video*.swift               # Pantallas de video (incl. Reels)
│   │   ├── Info.plist                 # UIBackgroundModes audio, etc.
│   │   ├── sample_audio.mp3
│   │   └── sample_video.mp4
│   ├── Podfile
│   └── SDKQAiOS.xcodeproj
└── README.md
```

---

## Notas

- Los **IDs de contenido** y la lógica de cada caso están alineados con el proyecto Android **SDKQA** para poder comparar comportamiento entre plataformas.
- Para **Reels** se usa la misma configuración que en el sample **ReelActivity** de Mediastream (id, playerId, DEV, trackEnable false, showDismissButton, autoplay).
- En **Video Live DVR** hay logs `[SDK-QA]` con los valores de `dvrStart` y `dvrEnd` al elegir DVR Start o DVR VOD, para depuración.
