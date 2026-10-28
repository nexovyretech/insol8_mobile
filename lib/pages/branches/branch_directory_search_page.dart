import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/pages/branches/branch_card.dart';
import 'package:insol8_mobile/pages/branches/branch_detail_page.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

/// Search branches by name or location and open their details.
class BranchDirectorySearchPage extends StatefulWidget {
  const BranchDirectorySearchPage({
    super.key,
    required this.branches,
    required this.deviceRepository,
    required this.onboardingRepository,
  });

  final List<BranchData> branches;
  final DeviceRepository deviceRepository;
  final OnboardingRepository onboardingRepository;

  @override
  State<BranchDirectorySearchPage> createState() =>
      _BranchDirectorySearchPageState();
}

class _BranchDirectorySearchPageState extends State<BranchDirectorySearchPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  List<BranchData> get _matchingBranches {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.branches
        .where(
          (branch) =>
              branch.name.toLowerCase().contains(query) ||
              branch.address.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

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
              AppInnerPageHeader(
                title: 'Search Branch',
                titleFontSize: 24,
                onBack: () => Navigator.of(context).pop(),
                leadingTooltip: 'Back to branches',
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              TextField(
                controller: _searchController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
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

    final branches = _matchingBranches;
    if (branches.isEmpty) {
      return Center(
        child: Text(
          'No branches found.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.fieldHint, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: branches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final branch = branches[index];
        return BranchCard(
          branch: branch,
          cityOnlyAddress: true,
          searchResultStyle: true,
          onTap: () => Navigator.of(context).push(
            PageRouteBuilder<void>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, _, _) => BranchDetailPage(
                branch: branch,
                deviceRepository: widget.deviceRepository,
                onboardingRepository: widget.onboardingRepository,
              ),
            ),
          ),
        );
      },
    );
  }
}
