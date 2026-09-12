import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Riceve un feedback dal client (chiunque, anche guest), lo salva nella tabella
// `feedback` (service role) e invia un'email di avviso al titolare via Resend.
// Secret richiesto: RESEND_API_KEY (impostato nel dashboard Supabase).
// Secret opzionali: FEEDBACK_FROM (mittente verificato su Resend, es.
//   "PitLap Feedback <noreply@pitlap.app>") e FEEDBACK_TO (destinatario).
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY sono iniettati automaticamente.

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  try {
    const { message, contactEmail, page, userId } = await req.json();
    const msg = (message ?? "").toString().trim();
    if (!msg || msg.length > 5000) return json({ error: "invalid message" }, 400);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { error: insErr } = await supabase.from("feedback").insert({
      message: msg,
      contact_email: contactEmail || null,
      user_id: userId || null,
      page: page || null,
      user_agent: req.headers.get("user-agent"),
    });
    if (insErr) throw insErr;

    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (resendKey) {
      const r = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${resendKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: Deno.env.get("FEEDBACK_FROM") ??
            "PitLap Feedback <onboarding@resend.dev>",
          to: [Deno.env.get("FEEDBACK_TO") ?? "beppe.apps@gmail.com"],
          subject: "Nuovo feedback PitLap",
          text:
            `Messaggio:\n${msg}\n\nEmail contatto: ${contactEmail || "-"}\n` +
            `Utente: ${userId || "guest"}\nPagina: ${page || "-"}`,
        }),
      });
      if (!r.ok) {
        console.error("Resend error", r.status, await r.text());
      }
    }
    return json({ ok: true });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});
