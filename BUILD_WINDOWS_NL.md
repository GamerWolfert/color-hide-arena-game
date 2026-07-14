# Windows release build

## Voorbereiding

1. Installeer de Godot 4.7 export templates in de editor.
2. Open het project in Godot.
3. Controleer in **Project > Export** de preset **Windows Desktop**.
4. Kies in de editor een geldig release-icoon als de SVG op jouw Godot-installatie niet als Windows-icoon wordt geaccepteerd.

## Exporteren

De preset schrijft naar:

`builds/windows/ColorHideArena.exe`

Via de editor:

`Project > Export > Windows Desktop > Export Project`

Via de terminal:

```powershell
Godot_v4.7-stable_win64.exe --path D:\GodotProjects\color_hide_arena --headless --export-release "Windows Desktop"
```

De releasepreset gebruikt x86_64, een ingebedde PCK, het eigen Color Hide Arena-icoon en de bestaande toetsenbord/muisbesturing. Fullscreen en windowed blijven beschikbaar via de bestaande instellingen. De GameCursor blijft in de game actief; in menu's wordt de normale muis gebruikt.

## Testen

- Start `ColorHideArena.exe`.
- Controleer login, hoofdmenu, fullscreen/windowed, muis en GameCursor.
- Test minimaal een volledige trainingsronde voordat je een release archiveert.

Een Windows signing-certificaat is bewust niet opgenomen. Voeg signing alleen lokaal toe via de Godot exportinstellingen.
