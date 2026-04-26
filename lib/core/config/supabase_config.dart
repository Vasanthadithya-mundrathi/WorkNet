class WorkNetSupabaseConfig {
  static const url = String.fromEnvironment(
    'WORKNET_SUPABASE_URL',
    defaultValue: 'https://dhxfjgnahczgljjiulcy.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'WORKNET_SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_qub91izo3oLy8yhmudRgqA_xIkPuQBl',
  );
  static const channel = String.fromEnvironment('WORKNET_SUPABASE_CHANNEL',
      defaultValue: 'global');

  static bool get isConfigured =>
      url.startsWith('https://') &&
      url.contains('.supabase.co') &&
      publishableKey.startsWith('sb_publishable_');
}
