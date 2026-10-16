import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../state/taxi_provider.dart';

class TaxiPage extends StatefulWidget {
  const TaxiPage({super.key});

  @override
  State<TaxiPage> createState() => _TaxiPageState();
}

class _TaxiPageState extends State<TaxiPage> {
  final TextEditingController _destinationController = TextEditingController();

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  String _errorMessage(AppLocalizations l10n, TaxiError error) {
    return switch (error) {
      TaxiError.locationServicesDisabled => l10n.taxiLocationServicesDisabled,
      TaxiError.locationPermissionDenied => l10n.taxiLocationPermissionDenied,
      TaxiError.locationPermissionDeniedForever =>
        l10n.taxiLocationPermissionDeniedForever,
      TaxiError.locationUnavailable => l10n.taxiLocationUnavailable,
      TaxiError.destinationRequired => l10n.taxiDestinationRequired,
      TaxiError.destinationNotFound => l10n.taxiDestinationNotFound,
      TaxiError.uberClientNotConfigured => l10n.taxiClientIdNotConfigured,
    };
  }

  Future<void> _openUber(BuildContext context, TaxiProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = await provider.buildRideLink(_destinationController.text);
    if (!context.mounted) return;

    if (uri == null) {
      final error = provider.error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(l10n, error))),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted || launched) return;
    } on PlatformException {
      if (!context.mounted) return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.taxiOpenUberFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<TaxiProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text_691)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              Icons.local_taxi_rounded,
              size: 56,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.taxiPageTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.taxiEstimatePending,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: provider.isLocating
                          ? null
                          : provider.useCurrentLocation,
                      icon: provider.isLocating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        provider.hasPickupLocation
                            ? l10n.taxiPickupLocationReady
                            : l10n.taxiUseCurrentLocation,
                      ),
                    ),
                    if (provider.hasPickupLocation) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${provider.pickupLatitude!.toStringAsFixed(5)}, '
                        '${provider.pickupLongitude!.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextField(
                      controller: _destinationController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.taxiDestinationLabel,
                        hintText: l10n.taxiDestinationHint,
                        prefixIcon: const Icon(Icons.place_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: provider.isPreparingRide
                          ? null
                          : () => _openUber(context, provider),
                      icon: provider.isPreparingRide
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.open_in_new),
                      label: Text(l10n.taxiOpenUber),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.taxiUberClientIdInfo,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
