import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/privacy/wave_quota.dart';
import '../../core/theme/app_spacing.dart';

/// Paywall. Con [AppConfig.plusEnabled] en falso solo anota la lista de espera.
class PlusScreen extends StatelessWidget {
  const PlusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final monthly = ClpFormat.pesos(4990);
    final annual = ClpFormat.pesos(29990);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picaflor Plus'),
        leading: IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Más radio y saludos, cuando haya gente cerca.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Saludos ilimitados (hoy gratis: ${WaveQuota.freeDailyLimit} al día).'),
          const Text('Radio hasta 10 km.'),
          const Text('Nota corta en el saludo.'),
          const Text('Modo incógnito.'),
          const SizedBox(height: AppSpacing.xl),
          Text(
            annual,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const Text('al año · IVA incluido · precios propuestos, no finales'),
          const SizedBox(height: AppSpacing.sm),
          Text('O $monthly al mes · IVA incluido'),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () {
              const message = AppConfig.plusEnabled
                  ? 'La compra en tienda se activa con RevenueCat cuando existan las cuentas.'
                  : 'Quedaste en la lista de espera. Todavía no se cobra.';
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(message)),
              );
            },
            child: const Text(AppConfig.plusEnabled ? 'Continuar' : 'Avisarme'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restaurar compras estará en la app de las tiendas.'),
                ),
              );
            },
            child: const Text('Restaurar compras'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'La suscripción se renueva sola hasta que la canceles en la tienda. '
            'Cancelar es tan fácil como contratar. La seguridad de la app no se cobra.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
