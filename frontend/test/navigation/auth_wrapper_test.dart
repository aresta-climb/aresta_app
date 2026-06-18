import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/navigation/auth_wrapper.dart';
import 'package:frontend/pages/onboarding_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:frontend/services/terms_service.dart';
import 'package:frontend/constants/legal_version.g.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSession extends Mock implements Session {}
class MockUser extends Mock implements User {}
class MockTermsService extends Mock implements TermsService {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockTermsService mockTermsService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockTermsService = MockTermsService();
    
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
  });

  Widget createWrapper(SharedPreferences prefs) {
    return MaterialApp(
      home: AuthWrapper(
        child: const Scaffold(body: Center(child: Text('App Content'))),
        supabaseClient: mockSupabase,
        termsService: mockTermsService,
        prefs: prefs,
      ),
    );
  }

  group('AuthWrapper', () {
    testWidgets('shows OnboardingPage if not seen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createWrapper(prefs));
      await tester.pump();

      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('shows TermsOfUsePage if onboarding seen but terms not accepted and not logged in', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_seen': true,
      });
      final prefs = await SharedPreferences.getInstance();

      when(() => mockAuth.currentSession).thenReturn(null);

      await tester.pumpWidget(createWrapper(prefs));
      await tester.pump();

      expect(find.byType(TermsOfUsePage), findsOneWidget);
    });

    testWidgets('shows LoginPage if terms accepted and not logged in', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_seen': true,
        'accepted_legal_version': kLegalVersion,
      });
      final prefs = await SharedPreferences.getInstance();

      when(() => mockAuth.currentSession).thenReturn(null);

      await tester.pumpWidget(createWrapper(prefs));
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('shows TermsOfUsePage if logged in but terms are outdated in metadata and local', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_seen': true,
        'accepted_legal_version': kLegalVersion - 1,
      });
      final prefs = await SharedPreferences.getInstance();

      final mockSession = MockSession();
      final mockUser = MockUser();
      
      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockUser.userMetadata).thenReturn({'accepted_terms_version': kLegalVersion - 1});

      await tester.pumpWidget(createWrapper(prefs));
      await tester.pump();

      expect(find.byType(TermsOfUsePage), findsOneWidget);
    });

    testWidgets('shows HomePage if logged in and terms accepted in metadata', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_seen': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final mockSession = MockSession();
      final mockUser = MockUser();
      
      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockUser.userMetadata).thenReturn({'accepted_terms_version': kLegalVersion});

      await tester.pumpWidget(createWrapper(prefs));
      await tester.pump();

      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('shows HomePage if logged in and terms accepted locally but metadata fails (offline-first)', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_seen': true,
        'accepted_legal_version': kLegalVersion,
      });
      final prefs = await SharedPreferences.getInstance();

      final mockSession = MockSession();
      final mockUser = MockUser();
      
      when(() => mockAuth.currentSession).thenReturn(mockSession);
      when(() => mockSession.user).thenReturn(mockUser);
      // Backend metadata might be missing if offline sync hasn't occurred
      when(() => mockUser.userMetadata).thenReturn(null);

      await tester.pumpWidget(createWrapper(prefs));
      await tester.pump();

      expect(find.text('App Content'), findsOneWidget);
    });
  });
}
