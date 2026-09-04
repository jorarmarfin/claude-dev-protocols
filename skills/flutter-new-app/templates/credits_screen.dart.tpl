import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/constants/app_constants.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créditos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Thank you card ──────────────────────────────────────────────────
          FadeInDown(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.primaryTeal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Gracias por usar {{APP_NAME}} y apoyar {{APP_PROPOSITO}}.',
                      style: const TextStyle(fontSize: 14, color: AppColors.darkSlate, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Desarrollador ───────────────────────────────────────────────────
          FadeInDown(delay: const Duration(milliseconds: 80), child: _SectionLabel(label: 'Desarrollador')),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: _CreditTile(
              icon: Icons.code_rounded,
              title: 'Ing. Software',
              subtitle: 'Luis Fernando Mayta Campos',
            ),
          ),
          FadeInDown(
            delay: const Duration(milliseconds: 120),
            child: _CreditTile(
              icon: Icons.language_rounded,
              title: 'Sitio Web',
              subtitle: 'luisitomayta.com',
              onTap: () => _launchUrl('https://luisitomayta.com'),
              isLink: true,
            ),
          ),

          // ── Tecnología ──────────────────────────────────────────────────────
          FadeInDown(delay: const Duration(milliseconds: 160), child: _SectionLabel(label: 'Tecnología')),
          FadeInDown(
            delay: const Duration(milliseconds: 180),
            child: _CreditTile(
              icon: Icons.flutter_dash_rounded,
              title: 'Framework',
              subtitle: 'Flutter',
            ),
          ),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: _CreditTile(
              icon: Icons.data_object_rounded,
              title: 'Lenguaje',
              subtitle: 'Dart',
            ),
          ),
          FadeInDown(
            delay: const Duration(milliseconds: 220),
            child: _CreditTile(
              icon: Icons.design_services_rounded,
              title: 'Diseño',
              subtitle: 'Material 3 y arquitectura modular por features',
            ),
          ),

          // ── Compartir ───────────────────────────────────────────────────────
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 260),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _shareApp,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Compartir {{APP_NAME}}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side: const BorderSide(color: AppColors.primaryTeal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          // ── Footer ──────────────────────────────────────────────────────────
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Center(
              child: Text(
                '{{APP_FOOTER_FRASE}}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInUp(
            delay: const Duration(milliseconds: 320),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'v${AppConstants.appVersion}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _shareApp() {
    Share.share(
      'Descarga {{APP_NAME}} — {{APP_PROPOSITO_CORTO}}.\n'
      'https://play.google.com/store/apps/details?id={{APPLICATION_ID}}',
      subject: '{{APP_NAME}}',
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6, left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _CreditTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLink;

  const _CreditTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryTeal, size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isLink ? AppColors.primaryTeal : AppColors.textSecondary,
            decoration: isLink ? TextDecoration.underline : null,
          ),
        ),
        trailing: onTap != null ? const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textSecondary) : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
