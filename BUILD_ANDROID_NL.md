# Android APK en AAB

## Instellingen

De Android presets gebruiken:

- package name: `com.gamerwolfert.colorhidearena`;
- landscape orientation;
- safe-area gedrag zonder edge-to-edge content;
- internetpermission voor Supabase en multiplayer;
- touchscreenbesturing via `DeviceService`, `InputService` en `MobileControls`;
- geen zichtbare GameCursor op mobiele apparaten;
- alleen ARM64 voor een compact performanceprofiel;
- immersive mode en vibratiepermission.

Verander het package name voordat je naar Google Play publiceert als dit project al door een andere app wordt gebruikt. Een package name is wereldwijd uniek.

## APK

Installeer eerst de Godot Android export templates en configureer Android SDK/OpenJDK 17 in Godot. Exporteer daarna preset **Android APK** naar:

`builds/android/ColorHideArena.apk`

Via de terminal:

```powershell
Godot_v4.7-stable_win64.exe --path D:\GodotProjects\color_hide_arena --headless --export-release "Android APK"
```

## AAB

Preset **Android AAB (Gradle)** gebruikt Gradle en schrijft naar:

`builds/android/ColorHideArena.aab`

Een AAB vereist een Gradle Android buildomgeving en een release-keystore. Configureer de keystore lokaal in Godot of via de Godot Android-keystore environment variables. Zet nooit keystorebestanden, wachtwoorden of signing keys in Git.

De officiele Godot-documentatie beschrijft dat AAB-export Gradle gebruikt en welke Android SDK/OpenJDK-stappen nodig zijn: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html>.

## Testen op Android

- Test landscape op een klein en groot scherm.
- Controleer notch/statusbar safe areas.
- Controleer joystick, touch-look, springen, sprinten, hurken en scanner.
- Controleer login via internet.
- Controleer dat er geen desktopmuiscursor verschijnt.
- Test met lage graphics en een zwakker Android-toestel.
