import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/terms_service.dart';
import 'package:frontend/constants/legal_version.g.dart'; // We assume this exists and has kLegalVersion

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TermsService', () {
    test('hasAcceptedCurrentTerms returns false when no terms are accepted', () async {
      final termsService = TermsService();
      final hasAccepted = await termsService.hasAcceptedCurrentTerms();
      expect(hasAccepted, isFalse);
    });

    test('hasAcceptedCurrentTerms returns false when accepted version is older', () async {
      SharedPreferences.setMockInitialValues({
        'accepted_legal_version': kLegalVersion - 1,
      });
      final termsService = TermsService();
      final hasAccepted = await termsService.hasAcceptedCurrentTerms();
      expect(hasAccepted, isFalse);
    });

    test('hasAcceptedCurrentTerms returns true when accepted version is current', () async {
      SharedPreferences.setMockInitialValues({
        'accepted_legal_version': kLegalVersion,
      });
      final termsService = TermsService();
      final hasAccepted = await termsService.hasAcceptedCurrentTerms();
      expect(hasAccepted, isTrue);
    });

    test('acceptTermsLocally saves current version and timestamp', () async {
      final termsService = TermsService();
      await termsService.acceptTermsLocally();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('accepted_legal_version'), equals(kLegalVersion));
      expect(prefs.getString('accepted_legal_timestamp'), isNotNull);
      expect(DateTime.tryParse(prefs.getString('accepted_legal_timestamp')!), isNotNull);
    });
  });
}
