import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontSize: 12, height: 1.45);
    final headingStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.3,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.pageVertical,
            AppSpacing.pageHorizontal,
            AppSpacing.pageVertical,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: AppColors.ink,
                  tooltip: 'Back',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                document.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 17, height: 1.25),
              ),
              const SizedBox(height: 4),
              Text(
                'Last updated: ${document.lastUpdated}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.body, fontSize: 10),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final paragraph in document.introduction) ...[
                          Text(paragraph, style: bodyStyle),
                          const SizedBox(height: 14),
                        ],
                        for (final section in document.sections) ...[
                          Text(section.heading, style: headingStyle),
                          const SizedBox(height: 8),
                          for (final paragraph in section.paragraphs) ...[
                            Text(paragraph, style: bodyStyle),
                            const SizedBox(height: 10),
                          ],
                          for (final group in section.bulletGroups) ...[
                            if (group.label != null) ...[
                              Text(
                                group.label!,
                                style: bodyStyle?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            for (final item in group.items)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  bottom: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('•  ', style: bodyStyle),
                                    Expanded(
                                      child: Text(item, style: bodyStyle),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                          for (final paragraph
                              in section.closingParagraphs) ...[
                            Text(paragraph, style: bodyStyle),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
