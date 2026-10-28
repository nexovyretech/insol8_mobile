import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/pages/branches/add_branch_page.dart';
import 'package:insol8_mobile/pages/branches/branch_card.dart';
import 'package:insol8_mobile/pages/branches/branch_detail_page.dart';
import 'package:insol8_mobile/pages/branches/branch_directory_search_page.dart';
import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

enum _BranchFilter { all, open, closed }

class BranchesPage extends StatefulWidget {
  const BranchesPage({
    super.key,
    required this.authRepository,
    required this.branchRepository,
    required this.deviceRepository,
    required this.onboardingRepository,
    required this.subscriptionRepository,
  });

  final AuthRepository authRepository;
  final BranchRepository branchRepository;
  final DeviceRepository deviceRepository;
  final OnboardingRepository onboardingRepository;
  final SubscriptionRepository subscriptionRepository;

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  List<BranchData> _branches = const [];
  _BranchFilter _filter = _BranchFilter.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!await widget.authRepository.hasActiveSession()) {
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.getStarted, (_) => false);
        }
        return;
      }
      final profile = await widget.authRepository.loadProfile();
      final planId = await widget.subscriptionRepository.fetchPlanId(
        profile.username,
      );
      if (planId != 'monthly-org') {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.devices);
        }
        return;
      }
      final branches = await widget.branchRepository.fetchBranches();
      if (!mounted) return;
      setState(() {
        _branches = branches;
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _error = 'We couldn’t load your branches. Check your connection.';
        _loading = false;
      });
    }
  }

  List<BranchData> get _visibleBranches => _branches
      .where((branch) {
        final matchesFilter = switch (_filter) {
          _BranchFilter.all => true,
          _BranchFilter.open => branch.isOpen,
          _BranchFilter.closed => !branch.isOpen,
        };
        return matchesFilter;
      })
      .toList(growable: false);

  int _count(_BranchFilter filter) => _branches.where((branch) {
    return switch (filter) {
      _BranchFilter.all => true,
      _BranchFilter.open => branch.isOpen,
      _BranchFilter.closed => !branch.isOpen,
    };
  }).length;

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
              const SizedBox(height: AppSpacing.pageHeaderTop),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Branches',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add branch',
                    onPressed: _showAddBranchDialog,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Search branches',
                    onPressed: _openBranchSearch,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _BranchFilterBar(
                selected: _filter,
                counts: {
                  _BranchFilter.all: _count(_BranchFilter.all),
                  _BranchFilter.open: _count(_BranchFilter.open),
                  _BranchFilter.closed: _count(_BranchFilter.closed),
                },
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavigation(
        selectedIndex: 1,
        organizationPlan: true,
        onSelect: (index) {
          if (index == 1) return;
          if (index == 0) {
            Navigator.of(context)
                .popUntil((route) => route.settings.name == AppRoutes.home);
          } else if (index == 2) {
            Navigator.of(context).pushNamed(AppRoutes.analytics);
          } else if (index == 3) {
            _showSettings();
          }
        },
      ),
    ),
  );

  Future<void> _showAddBranchDialog() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddBranchPage(
          authRepository: widget.authRepository,
          branchRepository: widget.branchRepository,
        ),
      ),
    );
    if (created == true && mounted) await _load();
  }

  Future<void> _openBranchSearch() => Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => BranchDirectorySearchPage(
        branches: _branches,
        deviceRepository: widget.deviceRepository,
        onboardingRepository: widget.onboardingRepository,
      ),
    ),
  );

  Future<void> _showSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.logout, color: AppColors.primary),
          title: const Text('Sign out'),
          onTap: () async {
            Navigator.pop(context);
            await widget.authRepository.signOut();
            if (!mounted) return;
            Navigator.of(this.context)
                .pushNamedAndRemoveUntil(AppRoutes.getStarted, (_) => false);
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    final branches = _visibleBranches;
    if (branches.isEmpty) {
      return _EmptyBranchesState(filter: _filter);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: branches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => BranchCard(
          branch: branches[index],
          onTap: () => _openBranchDetails(branches[index]),
        ),
      ),
    );
  }

  Future<void> _openBranchDetails(BranchData branch) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BranchDetailPage(
            branch: branch,
            deviceRepository: widget.deviceRepository,
            onboardingRepository: widget.onboardingRepository,
          ),
        ),
      );
}

class _BranchFilterBar extends StatelessWidget {
  const _BranchFilterBar({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final _BranchFilter selected;
  final Map<_BranchFilter, int> counts;
  final ValueChanged<_BranchFilter> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final filter in _BranchFilter.values)
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(filter),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected == filter
                    ? AppColors.dashboardCard
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${switch (filter) {
                  _BranchFilter.all => 'All',
                  _BranchFilter.open => 'Open',
                  _BranchFilter.closed => 'Closed',
                }} (${counts[filter]})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected == filter
                      ? AppColors.ink
                      : AppColors.fieldHint,
                  fontSize: 12,
                  fontWeight: selected == filter
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _EmptyBranchesState extends StatelessWidget {
  const _EmptyBranchesState({required this.filter});

  final _BranchFilter filter;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.store_mall_directory_outlined,
          size: 38,
          color: AppColors.sectionLabel,
        ),
        const SizedBox(height: 12),
        Text(
          filter == _BranchFilter.closed
              ? 'No closed branches.'
              : 'No branches yet.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          "When you have closed branches permanently, you'll see it here.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.fieldHint),
        ),
      ],
    ),
  );
}
