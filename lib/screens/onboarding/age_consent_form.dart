import 'package:flutter/material.dart';

import '../../core/privacy/age_gate.dart';
import '../../core/theme/app_spacing.dart';

class AgeConsentForm extends StatelessWidget {
  const AgeConsentForm({
    super.key,
    required this.birthDate,
    required this.termsAccepted,
    required this.analyticsAccepted,
    required this.onBirthDate,
    required this.onTerms,
    required this.onAnalytics,
  });

  final DateTime? birthDate;
  final bool termsAccepted;
  final bool analyticsAccepted;
  final ValueChanged<DateTime> onBirthDate;
  final ValueChanged<bool> onTerms;
  final ValueChanged<bool> onAnalytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adult = birthDate != null && AgeGate.isAdult(birthDate!, DateTime.now());
    final label = birthDate == null
        ? 'Fecha de nacimiento'
        : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const Spacer(),
          Text(
            'Edad y consentimiento',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Picaflor es para mayores de 18. Tu zona se comparte aproximada, nunca el punto exacto.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(now.year - 25),
                firstDate: DateTime(now.year - 100),
                lastDate: now,
                helpText: 'Fecha de nacimiento',
              );
              if (picked != null) onBirthDate(picked);
            },
            child: Text(label),
          ),
          if (birthDate != null && !adult) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tienes que tener 18 años o más.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          CheckboxListTile(
            value: termsAccepted,
            onChanged: (v) => onTerms(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Acepto los Términos y la Política de Privacidad',
            ),
          ),
          CheckboxListTile(
            value: analyticsAccepted,
            onChanged: (v) => onAnalytics(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Quiero ayudar con métricas de uso (opcional)'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
