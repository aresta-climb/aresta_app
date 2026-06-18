import 'package:flutter/material.dart';
import 'package:frontend/pages/onboarding_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/services/terms_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/constants/legal_version.g.dart';

class AuthWrapper extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  final TermsService? termsService;
  final SharedPreferences? prefs; // Injetável para testes
  final Widget child; // Página principal

  const AuthWrapper({
    super.key,
    required this.child,
    this.supabaseClient,
    this.termsService,
    this.prefs,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<SharedPreferences> _prefsFuture;
  late TermsService _termsService;

  @override
  void initState() {
    super.initState();
    _prefsFuture = widget.prefs != null 
        ? Future.value(widget.prefs!) 
        : SharedPreferences.getInstance();
    _termsService = widget.termsService ?? TermsService();
  }

  void _markOnboardingSeen() async {
    final prefs = await _prefsFuture;
    await prefs.setBool('onboarding_seen', true);
    setState(() {}); // Reconstroi o wrapper
  }

  void _acceptTerms() async {
    await _termsService.acceptTermsLocally();
    
    final client = widget.supabaseClient ?? Supabase.instance.client;
    final user = client.auth.currentUser;
    
    if (user != null) {
      // Atualiza o perfil no Supabase se logado
      await client.auth.updateUser(
        UserAttributes(data: {'accepted_terms_version': kLegalVersion}),
      );
    }
    
    setState(() {}); // Avança
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final prefs = snapshot.data!;
        final hasSeenOnboarding = prefs.getBool('onboarding_seen') ?? false;

        // 1. Onboarding
        if (!hasSeenOnboarding) {
          // Passamos callback para quando o usuário terminar o onboarding
          return OnboardingPage(onDone: _markOnboardingSeen);
        }

        // 2. Termos Locais (Primeiro acesso)
        final acceptedLocalVersion = prefs.getInt('accepted_legal_version') ?? 0;
        final hasAcceptedLocalTerms = acceptedLocalVersion >= kLegalVersion;

        final client = widget.supabaseClient ?? Supabase.instance.client;

        return StreamBuilder<AuthState>(
          stream: client.auth.onAuthStateChange,
          builder: (context, authSnapshot) {
            // Pegamos o estado atual ou do stream
            final session = authSnapshot.hasData 
                ? authSnapshot.data!.session 
                : client.auth.currentSession;
                
            final isLogged = session != null;

            // Se NÃO tá logado, depende apenas dos termos locais
            if (!isLogged) {
              if (!hasAcceptedLocalTerms) {
                return TermsOfUsePage(onAccepted: _acceptTerms, showAcceptButton: true);
              }
              return const LoginPage();
            }

            // Se TÁ logado, a fonte da verdade são os metadados do Supabase
            // Mas, offline-first: a gente também confia no SharedPreferences.
            // Se o local tá OK, ou o metadata tá OK, deixa passar.
            final user = session.user;
            final metaVersion = user.userMetadata?['accepted_terms_version'] as int? ?? 0;
            
            final isTermsOk = metaVersion >= kLegalVersion || hasAcceptedLocalTerms;

            if (!isTermsOk) {
              return TermsOfUsePage(onAccepted: _acceptTerms, showAcceptButton: true);
            }

            return widget.child;
          },
        );
      },
    );
  }
}
