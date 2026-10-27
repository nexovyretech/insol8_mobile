import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/pages/devices/device_card.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

/// Search page for devices returned by the device repository.
class DeviceSearchPage extends StatefulWidget {
  const DeviceSearchPage({
    super.key,
    required this.authRepository,
    required this.deviceRepository,
  });

  final AuthRepository authRepository;
  final DeviceRepository deviceRepository;

  @override
  State<DeviceSearchPage> createState() => _DeviceSearchPageState();
}

class _DeviceSearchPageState extends State<DeviceSearchPage> {
  final _searchController = TextEditingController();
  List<DeviceData> _devices = const [];
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadDevices();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  Future<void> _loadDevices() async {
    try {
      if (!await widget.authRepository.hasActiveSession()) {
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.getStarted, (_) => false);
        }
        return;
      }
      final devices = await widget.deviceRepository.fetchDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'We couldn’t load your devices. Check your connection.';
        _isLoading = false;
      });
    }
  }

  List<DeviceData> get _matchingDevices {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _devices
        .where((device) {
          final name = device.name.toLowerCase();
          if (name.contains(query)) return true;

          final queryWords = _searchWords(query);
          final deviceWords = _searchWords(name);
          return queryWords.every(deviceWords.contains);
        })
        .toList(growable: false);
  }

  List<String> _searchWords(String value) => value
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => int.tryParse(word)?.toString() ?? word)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 42),
              Text(
                'Search Devices',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 34),
              TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search branches',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.fieldHint,
                    size: 24,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          tooltip: 'Clear search',
                          icon: const Icon(
                            Icons.cancel,
                            color: AppColors.disabled,
                            size: 20,
                          ),
                        ),
                  filled: true,
                  fillColor: AppColors.dashboardCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildResults() {
    if (_searchController.text.trim().isEmpty) return const SizedBox.shrink();
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.body),
            ),
            TextButton(onPressed: _loadDevices, child: const Text('Try again')),
          ],
        ),
      );
    }

    final matches = _matchingDevices;
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No devices found.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.fieldHint, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 0, bottom: 16),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => DeviceCard(
        device: matches[index],
        onTap: () =>
            Navigator.of(context)
                .pushNamed(AppRoutes.deviceDetails, arguments: matches[index]),
      ),
    );
  }
}
