import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/constants/legal_version.g.dart';

class TermsService {
  static const String _versionKey = 'accepted_legal_version';
  static const String _timestampKey = 'accepted_legal_timestamp';

  Future<bool> hasAcceptedCurrentTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final acceptedVersion = prefs.getInt(_versionKey) ?? 0;
    return acceptedVersion >= kLegalVersion;
  }

  Future<void> acceptTermsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_versionKey, kLegalVersion);
    await prefs.setString(_timestampKey, DateTime.now().toIso8601String());
  }

  // Preparação para futura integração com backend (PowerSync/Supabase)
  Future<void> syncTermsToBackend() async {
    // Aqui no futuro será implementada a inserção/atualização
    // na tabela 'profiles' do banco de dados local SQLite (PowerSync)
    // Exemplo:
    // await db.execute('UPDATE profiles SET accepted_terms_version = ? WHERE id = ?', [kLegalVersion, userId]);
  }
}
