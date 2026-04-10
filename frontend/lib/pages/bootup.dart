import 'package:flutter/material.dart';
import '../services/dataset_repository.dart';
import '../navigation_wrapper.dart';
import '../functions/common_functions.dart';

/// The initial screen shown when the app launches.
/// 
/// Its primary responsibilities are:
/// 1. Bootstrapping the DatasetRepository (fetching the remote index).
/// 2. Providing a branded "loading" experience to the user.
/// 3. Navigating to the main app interface once initialization is complete.
class BootupScreen extends StatefulWidget {
  const BootupScreen({super.key});

  @override
  State<BootupScreen> createState() => _BootupScreenState();
}

class _BootupScreenState extends State<BootupScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final datasetRepo = DatasetRepository();
    
    // We use a stopwatch to track how long the initialization takes.
    // This allows us to enforce a minimum "splash" time so the screen
    // doesn't just flicker for a split second on fast connections.
    final stopwatch = Stopwatch()..start();
    
    // Initialize the repository by fetching the remote indice.binarypb.
    await datasetRepo.initialize();
    
    // Ensure the splash screen stays for at least 200ms for visual consistency.
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 200) {
      await Future.delayed(Duration(milliseconds: 200 - elapsed));
    }

    if (mounted) {
      // Transition to the main navigation wrapper.
      // We use PageRouteBuilder with a FadeTransition animation for a polished feel.
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              MainNavigationWrapper(
                key: MainNavigationWrapper.navKey,
                datasetRepo: datasetRepo
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: App Branding/Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: beastHide.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.terrain_rounded,
                color: beastHide,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'KMON',
              style: TextStyle(
                color: fishBone,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 60),
            // Indication that something is happening in the background
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: beastHide,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
