import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final SupabaseClient _supabase;
  final bool _isIOS;

  AuthService({
    SupabaseClient? supabase, 
    bool? isIOS,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _isIOS = isIOS ?? Platform.isIOS;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithGoogle({
    Future<GoogleSignInAccount> Function()? googleSignInProvider
  }) async {
    final googleSignInMethod = googleSignInProvider ?? GoogleSignIn.instance.authenticate;
    try {
      final googleUser = await googleSignInMethod();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Nenhum ID Token encontrado.');
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      if (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Login com o Google foi cancelado.');
      }
      rethrow;
    }
  }

  Future<AuthResponse> signInWithApple({
    Future<AuthorizationCredentialAppleID> Function(
      {required List<AppleIDAuthorizationScopes> scopes, String? nonce}
    )? getAppleIDCredential
  }) async {
    if (!_isIOS) {
      throw Exception('Login com a Apple só é suportado no iOS.');
    }
    
    // Usa a injeção via parâmetro para testes ou o nativo do plugin
    final credentialFetcher = getAppleIDCredential ?? SignInWithApple.getAppleIDCredential;
    
    final rawNonce = _supabase.auth.generateRawNonce();
    final bytes = utf8.encode(rawNonce);
    final digest = sha256.convert(bytes);
    final hashedNonce = digest.toString();

    final appleCredential = await credentialFetcher(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw Exception('Nenhum Apple ID Token encontrado.');
    }

    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<void> signInWithMagicLink(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'io.supabase.aresta://login-callback/',
    );
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _supabase.auth.signOut();
  }
}
