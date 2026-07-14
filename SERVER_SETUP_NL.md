# Linux headless server

## Export

Installeer de Godot export templates en exporteer preset **Linux Headless Server** naar:

`builds/server/color_hide_arena_server.x86_64`

De preset gebruikt een dedicated-server export met de feature `dedicated_server`, x86_64 en zonder shader baking.

## Starten

Maak het script uitvoerbaar en start de server:

```bash
chmod +x server_start.sh
./server_start.sh
```

De standaardpoort is `24590`. Een andere poort:

```bash
COLOR_HIDE_ARENA_PORT=24596 ./server_start.sh
```

Open de gekozen ENet-serverpoort in de firewall. Voor een lokale test kan ook rechtstreeks worden gestart:

```bash
./builds/server/color_hide_arena_server.x86_64 --headless -- --server --port=24590
```

Op Windows is `server_start.bat` toegevoegd voor een lokale headless smoke test met de Godot-editor. Zet eventueel `GODOT_BIN` naar het volledige pad van `Godot_v4.7-stable_win64.exe`. De echte productie-server blijft de Linux-export uit deze handleiding.

## Supabase-statistieken

Zet een server-token alleen in de serveromgeving als de beveiligde Supabase Edge Function is gedeployed. Zet geen token in het project, de exportpreset of Git. De Godot-server gebruikt command-line poortconfiguratie en logt geen tokens.

## Testen

1. Start de server.
2. Controleer `DEDICATED_SERVER_READY` en `NETWORK_SERVER_READY`.
3. Verbind twee clients naar dezelfde poort.
4. Controleer rollen, timer, beweging, treffers en round results.

Godot beschrijft dedicated-server exports en het starten daarvan in de officiele exportdocumentatie: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html>.
