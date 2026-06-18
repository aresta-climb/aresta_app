import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

void main() {
  late AuthService authService;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockSupabase.auth).thenReturn(mockAuth);

    authService = AuthService(
      supabase: mockSupabase,
      isIOS: true,
    );
  });

  group('AuthService', () {
    test('signInWithGoogle throws exception when canceled via exception', () async {
      expect(
        () => authService.signInWithGoogle(googleSignInProvider: () async {
          throw const GoogleSignInException(code: GoogleSignInExceptionCode.canceled);
        }),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('cancelado'))),
      );
    });



    test('signInWithMagicLink calls supabase signInWithOtp', () async {
      when(() => mockAuth.signInWithOtp(
        email: any(named: 'email'),
        emailRedirectTo: any(named: 'emailRedirectTo'),
      )).thenAnswer((_) async => {});

      await authService.signInWithMagicLink('test@example.com');

      verify(() => mockAuth.signInWithOtp(
        email: 'test@example.com',
        emailRedirectTo: 'io.supabase.aresta://login-callback/',
      )).called(1);
    });

    test('signInWithGoogle throws exception when id token is missing', () async {
      final mockUser = MockGoogleSignInAccount();
      final mockGoogleAuth = MockGoogleSignInAuthentication();
      
      when(() => mockUser.authentication).thenReturn(mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn(null);

      expect(
        () => authService.signInWithGoogle(googleSignInProvider: () async => mockUser),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Nenhum ID Token'))),
      );
    });

    test('signInWithApple throws exception if not iOS', () async {
      final nonIosAuthService = AuthService(
        supabase: mockSupabase,
        isIOS: false,
      );

      expect(
        () => nonIosAuthService.signInWithApple(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('suportado no iOS'))),
      );
    });

    test('signInWithApple throws exception if id token is missing', () async {
      Future<AuthorizationCredentialAppleID> mockGetAppleIDCredential({
        required List<AppleIDAuthorizationScopes> scopes,
        String? nonce,
      }) async {
        return AuthorizationCredentialAppleID(
          authorizationCode: 'code',
          identityToken: null, // missing token
          userIdentifier: 'user',
          givenName: 'Test',
          familyName: 'User',
          email: 'test@apple.com',
          state: 'state',
        );
      }

      expect(
        () => authService.signInWithApple(getAppleIDCredential: mockGetAppleIDCredential),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Nenhum Apple ID Token'))),
      );
    });
  });
}
