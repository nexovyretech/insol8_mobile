import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

/// Search and select a branch for a device assignment.
class BranchSearchPage extends StatefulWidget {
  const BranchSearchPage({super.key, required this.branches});

  final List<String> branches;

  @override
  State<BranchSearchPage> createState() => _BranchSearchPageState();
}

class _BranchSearchPageState extends State<BranchSearchPage> {
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

  List<String> get _matchingBranches {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.branches
        .where((branch) => branch.toLowerCase().contains(query))
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
              const SizedBox(height: 42),
              Text(
                'Search Branch',
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.fieldHint,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: branches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _BranchResultCard(
        name: branches[index],
        onTap: () => Navigator.of(context).pop(branches[index]),
      ),
    );
  }
}

class _BranchResultCard extends StatelessWidget {
  const _BranchResultCard({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (name.toLowerCase()) {
      'bagumbong' || 'bagong silang' =>
        'Caloocan City  |  6 Dryers  |  5 Active Cycles',
      'camarin' => 'Caloocan City  |  2 Dryers  |  2 Active Cycles',
      _ => 'Available branch',
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.dashboardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A35170F),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.sectionLabel,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.fieldHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Jane Doe',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.fieldHint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Icon(
                    Icons.circle,
                    size: 12,
                    color: AppColors.sectionLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
