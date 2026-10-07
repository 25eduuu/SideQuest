const CONSENT_VERSION = 'beta-2026-10-07-v2';
const json = (body, status = 200) => new Response(JSON.stringify(body), {status, headers:{'content-type':'application/json; charset=utf-8','cache-control':'no-store'}});

export async function onRequestPost({request, env}) {
  const origin = request.headers.get('Origin');
  const requestUrl = new URL(request.url);
  if (!origin || new URL(origin).origin !== requestUrl.origin) return json({ok:false,message:'Richiesta non valida.'}, 403);
  if (env.BETA_SIGNUPS_ENABLED !== 'true') return json({ok:false,message:'Le iscrizioni beta non sono ancora aperte.'}, 503);
  if (!env.TURNSTILE_SECRET_KEY || !env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) return json({ok:false,message:'Configurazione beta incompleta.'}, 503);
  const length = Number(request.headers.get('Content-Length') || 0);
  if (length > 8192) return json({ok:false,message:'Richiesta troppo grande.'}, 413);
  let body;
  try { body = await request.json(); } catch { return json({ok:false,message:'Dati non validi.'}, 400); }
  if (!body || typeof body !== 'object' || Array.isArray(body)) return json({ok:false,message:'Dati non validi.'}, 400);
  if (typeof body.website === 'string' && body.website.trim()) return json({ok:true});
  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
  const platform = body.platform;
  const usernameRaw = typeof body.telegram_username === 'string' ? body.telegram_username.trim().replace(/^@/, '') : '';
  const telegram_username = usernameRaw ? `@${usernameRaw}` : null;
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254 || !['android','ios'].includes(platform) || body.privacy_consent !== true || body.age_confirmed !== true) return json({ok:false,message:'Controlla i campi e le conferme richieste.'}, 400);
  if (platform === 'android' && (!telegram_username || !/^@[A-Za-z0-9_]{5,32}$/.test(telegram_username))) return json({ok:false,message:'Inserisci uno username Telegram valido.'}, 400);
  const token = typeof body.turnstile_token === 'string' ? body.turnstile_token : '';
  if (!token || token.length > 2048) return json({ok:false,message:'Completa la verifica anti-spam.'}, 400);
  try {
    const verifyBody = new URLSearchParams({secret:env.TURNSTILE_SECRET_KEY,response:token});
    const remoteIp = request.headers.get('CF-Connecting-IP');
    if (remoteIp) verifyBody.set('remoteip', remoteIp);
    const verifyResponse = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},body:verifyBody});
    const verification = await verifyResponse.json();
    if (!verification.success || verification.action !== 'beta_signup' || verification.hostname !== requestUrl.hostname) return json({ok:false,message:'Verifica anti-spam non valida. Riprova.'}, 400);
    const supabaseUrl = env.SUPABASE_URL.replace(/\/$/, '');
    const insert = await fetch(`${supabaseUrl}/rest/v1/sq_beta_signups`, {method:'POST',headers:{apikey:env.SUPABASE_SERVICE_ROLE_KEY,authorization:`Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,'content-type':'application/json',prefer:'return=minimal,resolution=ignore-duplicates'},body:JSON.stringify({email,platform,telegram_username:platform === 'android' ? telegram_username : null,privacy_consent:true,age_confirmed:true,consent_version:CONSENT_VERSION,consent_at:new Date().toISOString()})});
    if (insert.status === 409) return json({ok:true});
    if (!insert.ok) return json({ok:false,message:'Servizio momentaneamente non disponibile.'}, 503);
    return json({ok:true});
  } catch {
    return json({ok:false,message:'Servizio momentaneamente non disponibile.'}, 503);
  }
}
