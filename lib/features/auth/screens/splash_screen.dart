import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';

/// Shown while the session is being resolved. Navigation is handled by the
/// router guard, so this screen never navigates itself (SPEC §85).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront, size: 96, color: scheme.onPrimary),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CircularProgressIndicator(color: scheme.onPrimary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
