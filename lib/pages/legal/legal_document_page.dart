import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontSize: 14, height: 1.5);
    final headingStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.ink,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.3,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.pageHeaderTop),
              AppInnerPageHeader(
                title: document.title,
                onBack: () => Navigator.of(context).maybePop(),
                titleFontSize: 18,
              ),
              const SizedBox(height: 2),
              Text(
                'Last updated: ${document.lastUpdated}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.body, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
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
