(() => {
  const form = document.querySelector('#beta-form');
  if (!form) return;
  const cfg = window.SIDEQUEST_CONFIG?.beta || {};
  const platform = form.elements.platform;
  const android = form.querySelector('.beta-android');
  const telegram = form.elements.telegram_username;
  const button = document.querySelector('#beta-submit');
  const status = document.querySelector('#beta-status');
  const captchaBox = document.querySelector('#beta-captcha');
  let widgetId = null;
  const tell = (message, kind = '') => { status.textContent = message; status.dataset.kind = kind; };
  const invite = () => typeof cfg.telegramInviteUrl === 'string' && /^https:\/\/(t\.me|telegram\.me)\/[A-Za-z0-9_+\-/]+$/.test(cfg.telegramInviteUrl);
  platform.addEventListener('change', () => {
    const isAndroid = platform.value === 'android';
    android.hidden = !isAndroid;
    telegram.required = isAndroid;
    telegram.autocomplete = 'off';
  });
  if (!cfg.enabled || !cfg.turnstileSiteKey) return;
  button.disabled = false;
  button.textContent = 'Richiedi accesso beta';
  tell('La richiesta viene registrata per gestire gli inviti beta. Non inviamo email automatiche.');
  const loadCaptcha = () => {
    if (window.turnstile || document.querySelector('#turnstile-script')) return;
    const script = document.createElement('script'); script.id = 'turnstile-script';
    script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit'; script.async = true; script.defer = true;
    script.onload = () => { widgetId = window.turnstile.render(captchaBox, {sitekey: cfg.turnstileSiteKey, action: 'beta_signup', theme: 'light'}); };
    script.onerror = () => tell('Verifica anti-spam non disponibile. Riprova più tardi.', 'error');
    document.head.appendChild(script);
  };
  form.addEventListener('focusin', loadCaptcha, {once: true});
  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (!form.reportValidity()) return;
    const data = new FormData(form);
    const token = widgetId !== null ? window.turnstile.getResponse(widgetId) : '';
    if (!token) { loadCaptcha(); tell('Completa la verifica anti-spam prima di inviare.', 'error'); return; }
    button.disabled = true; tell('Invio della richiesta…');
    const payload = {email:data.get('email'), platform:data.get('platform'), telegram_username:data.get('telegram_username'), privacy_consent:data.get('privacy_consent') === 'on', age_confirmed:data.get('age_confirmed') === 'on', website:data.get('website'), turnstile_token:token};
    try {
      const response = await fetch('/api/beta-signup', {method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(payload),credentials:'same-origin'});
      const result = await response.json().catch(() => ({}));
      if (!response.ok || !result.ok) throw new Error(result.message || 'Non siamo riusciti a registrare la richiesta.');
      form.reset(); android.hidden = true; telegram.required = false;
      tell(payload.platform === 'android' && invite() ? 'Richiesta registrata. Ora invia la richiesta di accesso al canale Telegram: approveremo il tuo username dopo il controllo della lista beta.' : 'Richiesta registrata. La beta iPhone è in preparazione; non inviamo email automatiche.', 'success');
      if (payload.platform === 'android' && invite()) { const a=document.createElement('a');a.href=cfg.telegramInviteUrl;a.target='_blank';a.rel='noopener noreferrer';a.textContent='Apri il canale Telegram ↗';a.className='button';status.after(a); }
    } catch (error) { tell(error.message || 'Errore temporaneo. Riprova più tardi.', 'error'); if (window.turnstile && widgetId !== null) window.turnstile.reset(widgetId); }
    finally { button.disabled = false; }
  });
})();
