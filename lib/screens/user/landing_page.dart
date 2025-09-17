import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final isSmall = c.maxHeight < 700;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 90),
                    // Image héro (réseau, remplaçable par asset)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 12 / 10,
                        child: Image.asset(
                          "assets/img/Blood donation-bro.png"
                        )
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Donnez du sang, sauvez des vies',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmall ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111418),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Recevez les demandes urgentes près de vous et aidez les patients à temps.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.65),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          elevation: 0,
                        ),
                        child: const Text('Commencer'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text("Créer un compte"),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        'En continuant, vous acceptez nos Conditions & Politique de confidentialité.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

