class SupabaseConfig {
  static const String url = 'https://haoyrdmvhiuoexqjoauu.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhhb3lyZG12aGl1b2V4cWpvYXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwODA2MDQsImV4cCI6MjA3NjY1NjYwNH0.FIL4Onv_vt1_G1yFcTCABEjmMHX3x23gxlkiNX447l0';
  
  static void printConfig() {
    print('🔧 Configuração do Supabase:');
    print('📡 URL: $url');
    print('🔑 Key: ${anonKey.substring(0, 20)}...');
  }
}

