# iOS Xcode-project

De preset **iOS Xcode Project** bereidt een iOS-project voor met:

- bundle identifier `com.gamerwolfert.colorhidearena`;
- iPhone en iPad als device family;
- ARM64;
- iOS 14.0 als minimumversie voor de Godot 4.7 renderer;
- touch-input via de bestaande mobiele inputlaag;
- netwerktoegang voor Supabase en multiplayer;
- project-only export, zodat Xcode de uiteindelijke build en signing doet.

De export komt in:

`builds/ios/ColorHideArena.xcodeproj`

## Belangrijke Apple-eis

Een iOS-build kan niet volledig op deze Windows-pc worden gemaakt. Exporteer het Xcode-project en open het daarna op een Mac met Xcode. Op de Mac zijn een Apple Developer-account, signing team, provisioning profile en certificaten nodig voor installatie op een iPhone/iPad of publicatie.

## Testen

- Open het project in Xcode op macOS.
- Controleer de bundle identifier en signing team.
- Test safe areas op een iPhone met notch en op iPad.
- Test touchbesturing en terugkeer uit pauze/login.
- Maak eerst een development build voordat je archiveert.

Godot documenteert iOS-export als een Xcode/Mac-workflow: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html>.
