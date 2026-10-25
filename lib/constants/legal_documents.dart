import 'package:insol8_mobile/models/legal_document.dart';

abstract final class LegalDocuments {
  static const terms = LegalDocument(
    title: 'inSOL8 Terms and Conditions',
    lastUpdated: 'September 2026',
    introduction: [
      'Welcome to inSOL8. These Terms & Conditions govern your use of the inSOL8 application and its related services. By creating an account or using inSOL8, you agree to these Terms.',
    ],
    sections: [
      LegalSection(
        heading: '1. Acceptance of Terms',
        paragraphs: [
          'By accessing or using inSOL8, you confirm that you have read, understood, and agree to these Terms & Conditions and our Privacy Policy.',
          'If you do not agree with these terms, please do not create an account or use the application.',
        ],
      ),
      LegalSection(
        heading: '2. About inSOL8',
        paragraphs: [
          'inSOL8 is a smart monitoring and control system designed to assist users in monitoring the operation and environmental conditions of a solar-powered drying system.',
          'Features may include monitoring system status, viewing sensor information, receiving notifications, and accessing other features provided through the application.',
        ],
      ),
      LegalSection(
        heading: '3. Account Registration',
        paragraphs: [
          'To use certain features, you may need to create an inSOL8 account.',
        ],
        bulletGroups: [
          LegalBulletGroup(
            label: 'You agree to:',
            items: [
              'Provide accurate and complete information during registration.',
              'Keep your account information up to date.',
              'Keep your password confidential.',
              'Keep your verification codes and other authentication credentials private.',
              'Notify the appropriate inSOL8 support contact if you believe your account has been accessed without authorization.',
            ],
          ),
        ],
        closingParagraphs: [
          'You are responsible for activities performed through your account unless caused by circumstances beyond your reasonable control.',
        ],
      ),
      LegalSection(
        heading: '4. Acceptable Use',
        paragraphs: [
          'You agree to use inSOL8 only for lawful purposes and in accordance with these Terms.',
        ],
        bulletGroups: [
          LegalBulletGroup(
            label: 'You must not:',
            items: [
              'Attempt to gain unauthorized access to another user’s account.',
              'Interfere with or disrupt the application’s operation.',
              'Circumvent security or authentication features.',
              'Use the application to transmit malicious software.',
              'Attempt to modify, reverse engineer, or compromise the system without authorization.',
            ],
          ),
        ],
      ),
      LegalSection(
        heading: '5. System Information and Monitoring',
        paragraphs: [
          'Information displayed by inSOL8 may depend on data received from connected sensors, devices, and other system components.',
          'While inSOL8 is designed to provide useful monitoring information, displayed readings may be affected by sensor limitations, connectivity issues, device conditions, or other technical factors. Users should not rely solely on the application for safety-critical decisions.',
        ],
      ),
      LegalSection(
        heading: '6. Availability of the Service',
        paragraphs: [
          'We may temporarily suspend or limit access to inSOL8 for maintenance, updates, security reasons, technical problems, or circumstances beyond our control.',
          'We will make reasonable efforts to maintain the availability of the service, but continuous or uninterrupted operation cannot be guaranteed.',
        ],
      ),
      LegalSection(
        heading: '7. Intellectual Property',
        paragraphs: [
          'The inSOL8 application, including its software, interface, graphics, logos, designs, and other original materials, is owned by or used with permission by the inSOL8/Nexovyre team and is protected by applicable intellectual property laws. You may not reproduce, modify, distribute, or commercially exploit these materials without appropriate authorization.',
        ],
      ),
      LegalSection(
        heading: '8. Privacy',
        paragraphs: [
          'Your use of inSOL8 is also governed by our Privacy Policy, which explains how we collect, use, store, and protect your personal information.',
        ],
      ),
      LegalSection(
        heading: '9. Changes to These Terms',
        paragraphs: [
          'We may update these Terms when necessary to reflect changes to the application, services, or applicable requirements.',
          'When significant changes are made, we will provide appropriate notice. Your continued use of inSOL8 after the updated Terms take effect means that you acknowledge the updated Terms.',
        ],
      ),
      LegalSection(
        heading: '10. Account Termination',
        paragraphs: [
          'You may request the deletion of your inSOL8 account, subject to applicable requirements and legitimate retention obligations.',
          'We may suspend or terminate an account when necessary to protect the service, other users, or the security of the system, including in cases of serious violations of these Terms.',
        ],
      ),
      LegalSection(
        heading: '11. Contact Us',
        paragraphs: [
          'If you have questions about these Terms & Conditions, please contact the inSOL8 support team.',
          'inSOL8 / Nexovyre Team\nEmail: nexovyre@gmail.com',
        ],
      ),
    ],
  );

  static const privacy = LegalDocument(
    title: 'inSOL8 Privacy Policy',
    lastUpdated: 'September 2026',
    introduction: [
      'Your privacy is important to us. This Privacy Policy explains how inSOL8 collects, uses, stores, and protects personal information when you use the application.',
      'This sample is structured around the transparency and data-subject principles under the Philippine Data Privacy Act of 2012 (Republic Act No. 10173).',
    ],
    sections: [
      LegalSection(
        heading: '1. Information We Collect',
        paragraphs: [
          'Depending on the features you use, inSOL8 may collect the following information:',
        ],
        bulletGroups: [
          LegalBulletGroup(
            label: 'Account information',
            items: [
              'Full name or username',
              'Email address',
              'Mobile number',
              'Password information',
              'Account verification information',
            ],
          ),
          LegalBulletGroup(
            label: 'System information',
            items: [
              'Temperature readings',
              'Environmental measurements',
              'Drying system status',
              'Device status',
              'System activity',
              'Other sensor data generated by connected devices',
            ],
          ),
          LegalBulletGroup(
            label: 'Technical information',
            items: [
              'Device type',
              'Operating system',
              'Application version',
              'Login and authentication activity',
              'Error and diagnostic information',
            ],
          ),
        ],
        closingParagraphs: [
          'Only information necessary for the stated purposes should actually be collected by the implemented system. Philippine privacy rules emphasize that personal data should be adequate and not excessive for the purpose of processing.',
        ],
      ),
      LegalSection(
        heading: '2. How We Use Your Information',
        paragraphs: ['We may use your information to:'],
        bulletGroups: [
          LegalBulletGroup(
            items: [
              'Create and manage your inSOL8 account.',
              'Verify your identity.',
              'Authenticate your login.',
              'Provide access to inSOL8 features.',
              'Display system and sensor information.',
              'Send account-related notifications.',
              'Maintain and improve the application’s functionality.',
              'Detect and address security or technical issues.',
              'Respond to support requests.',
            ],
          ),
        ],
        closingParagraphs: [
          'We will not use personal information for purposes incompatible with the purposes communicated to you.',
        ],
      ),
      LegalSection(
        heading: '3. How We Protect Your Information',
        paragraphs: [
          'We use reasonable technical, organizational, and administrative safeguards intended to protect personal information against unauthorized access, alteration, disclosure, loss, or destruction. These safeguards may include authentication controls, access restrictions, secure storage, and other appropriate security measures.',
          'However, no electronic system can guarantee absolute security. The Philippine Data Privacy Act requires appropriate safeguards and recognizes principles including transparency, legitimate purpose, and proportionality.',
        ],
      ),
      LegalSection(
        heading: '4. Sharing of Information',
        paragraphs: ['We do not sell your personal information.'],
        bulletGroups: [
          LegalBulletGroup(
            label: 'Personal information may be disclosed only when necessary for legitimate purposes, such as:',
            items: [
              'Providing and maintaining the inSOL8 service.',
              'Operating technical infrastructure or service providers.',
              'Complying with applicable laws or lawful requests.',
              'Protecting the security and integrity of the service.',
              'Responding to emergencies or other circumstances permitted by law.',
            ],
          ),
        ],
        closingParagraphs: [
          'When third-party service providers process personal information on our behalf, appropriate safeguards should be implemented.',
        ],
      ),
      LegalSection(
        heading: '5. Data Retention',
        paragraphs: [
          'We retain personal information only for as long as reasonably necessary to fulfill the purposes for which it was collected, provide the service, resolve disputes, maintain records, or comply with applicable legal obligations.',
          'When information is no longer necessary, it should be securely deleted, anonymized, or otherwise disposed of in accordance with applicable requirements. This is consistent with the Data Privacy Act’s principle that personal information should generally be retained only as long as necessary for its stated purposes or other lawful purposes.',
        ],
      ),
      LegalSection(
        heading: '6. Your Privacy Rights',
        paragraphs: [
          'Subject to applicable law, you may have rights regarding your personal information, including the right to:',
        ],
        bulletGroups: [
          LegalBulletGroup(
            items: [
              'Be informed about how your information is processed.',
              'Request access to your personal information.',
              'Request correction of inaccurate or incomplete information.',
              'Object to certain processing.',
              'Request deletion or blocking when legally applicable.',
              'Request data portability where applicable.',
              'Withdraw consent when processing is based on consent.',
            ],
          ),
        ],
      ),
      LegalSection(
        heading: '7. Cookies and Similar Technologies',
        paragraphs: [
          'If inSOL8 uses cookies, local storage, analytics tools, or similar technologies, these may be used to maintain sessions, remember preferences, improve performance, or understand how the application is used.',
          'The specific technologies used should be disclosed based on the actual implementation.',
        ],
      ),
      LegalSection(
        heading: '8. Children’s Privacy',
        paragraphs: [
          'inSOL8 is not intended to knowingly collect personal information from children without appropriate authorization or a lawful basis.',
          'If we become aware that personal information has been collected inappropriately, we will take reasonable steps to address the situation.',
        ],
      ),
      LegalSection(
        heading: '9. Changes to This Privacy Policy',
        paragraphs: [
          'We may update this Privacy Policy when our services, data-processing practices, or applicable requirements change.',
          'When significant changes are made, we will provide appropriate notice and update the Last updated date above.',
        ],
      ),
      LegalSection(
        heading: '10. Contact Us',
        paragraphs: [
          'For questions, requests, or concerns regarding your personal information, please contact:',
          'inSOL8 / Nexovyre Team\nEmail: privacy@insol8.example',
        ],
      ),
    ],
  );
}
