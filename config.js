/* Optional Supabase project settings. The anon/publishable key is designed to be public.
   Never put a service_role key here. Leave both values empty for offline/local mode. */
window.SIDEQUEST_CONFIG = {
  supabaseUrl: 'https://cfoavpouggogcbcdhpck.supabase.co',
  supabaseAnonKey: 'sb_publishable_iidyApVIbFozX0wTFFtjnw_q0AdrA70',
  // Add Google (or another provider) only after its OAuth credentials are configured.
  oauthProviders: [],
  // Add an AdSense display unit ID only after Sidequest is approved.
  // Ads stay off until enabled is true and a valid slot ID is present.
  ads: {
    enabled: false,
    client: 'ca-pub-2365902217564104',
    slots: { quests: '' }
  },
  // Add only real, clearly disclosed sponsorships / approved affiliate offers.
  // Example fields: id, title, prompt, emoji, duration, vibe, sponsorName,
  // disclosure, url (HTTPS), and cta. Leave empty until an agreement exists.
  sponsoredMissions: [],
  beta: {
    enabled: false,
    turnstileSiteKey: '',
    telegramInviteUrl: ''
  }
};
