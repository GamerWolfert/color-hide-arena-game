# Supabase Phase 7 setup

Deze map bevat de databaseconfiguratie voor profielen, cloud saves, statistieken, vrienden, recente spelers en de leaderboard.

## Eenmalige database-installatie

1. Open de Supabase SQL Editor.
2. Voer `phase7_profiles_friends_cloudsave.sql` uit.
3. Controleer daarna in Table Editor of de tabellen en RLS-policies aanwezig zijn.

## Veilige multiplayerstatistieken

Deploy `functions/record-match-stats/index.ts` als Edge Function. Stel alleen in de Supabase Edge Function-omgeving in:

- `COLOR_HIDE_ARENA_SERVER_TOKEN`: een lange willekeurige servertoken;
- `SUPABASE_SERVICE_ROLE_KEY`: de Supabase service-role key.

Deze waarden horen nooit in Godot, Git of de clientconfiguratie. De Godot dedicated server leest alleen `COLOR_HIDE_ARENA_SERVER_TOKEN` uit zijn lokale serveromgeving en logt de waarde niet.

## Clientconfiguratie

Godot gebruikt uitsluitend de Supabase URL en publishable key uit `scripts/services/supabase_config.gd`. RLS beperkt clienttoegang tot de eigen profiel-, save-, statistiek-, vrienden- en recente-spelersgegevens.
