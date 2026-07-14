import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-color-hide-server-token",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const expectedToken = Deno.env.get("COLOR_HIDE_ARENA_SERVER_TOKEN") ?? "";
  const suppliedToken = request.headers.get("x-color-hide-server-token") ?? "";
  if (expectedToken.length < 16 || suppliedToken.length < 16 || suppliedToken !== expectedToken) {
    return new Response(JSON.stringify({ error: "forbidden" }), { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  const payload = await request.json();
  if (!payload || typeof payload !== "object" || !Array.isArray(payload.players)) {
    return new Response(JSON.stringify({ error: "invalid_payload" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  for (const player of payload.players) {
    if (typeof player.user_id !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(player.user_id) || typeof player.role !== "string") continue;
    const role = player.role.toUpperCase();
    const increment = {
      user_id: player.user_id,
      rounds: 1,
      wins: player.won === true ? 1 : 0,
      losses: player.won === true ? 0 : 1,
      hider_rounds: role === "HIDER" ? 1 : 0,
      seeker_rounds: role === "SEEKER" ? 1 : 0,
      xp_earned: Number.isFinite(player.xp) ? Math.max(0, Math.floor(player.xp)) : 0,
    };
    const { error } = await supabase.rpc("record_authoritative_stats", { stat_row: increment });
    if (error) {
      return new Response(JSON.stringify({ error: "stats_write_failed" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
  }

  return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
});
