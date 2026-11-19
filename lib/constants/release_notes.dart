/// What changed in each version, shown in Settings > About Us > What's new.
///
/// Before tagging a release (git tag v0.6.4), add an entry at the TOP with the
/// same version as the tag, without the "v". Write for users, not developers.
class ReleaseNote {
  const ReleaseNote(this.version, this.changes);

  /// Matches the tag without "v", e.g. "0.6.3" for v0.6.3.
  final String version;
  final List<String> changes;
}

/// Newest first.
const releaseNotes = <ReleaseNote>[
  ReleaseNote('0.7.1', ['What’s new now shows the changes from 0.7.0.']),
  ReleaseNote('0.7.0', [
    'Account Profile: edit your name and username, and add or change your email and mobile number.',
    'Password & Security: connect Google, create a password for Google sign-ups, or update your password.',
    'Billing Information: see your plan, billing dates, and payment method, with payment history and PDF receipts.',
    'Change plan: upgrade for just the difference, switch to Basic at the end of your billing cycle, or cancel anytime.',
    'New prices: Basic ₱249.99 and Organization ₱499.99.',
    'A live password checklist, clearer error messages, and a resend timer on code screens.',
  ]),
  ReleaseNote('0.6.3', [
    'Check for updates and What’s new now live in Settings > About Us.',
    'About Us shows the version you have installed.',
  ]),
  ReleaseNote('0.6.2', [
    'A cleaner update screen with download progress.',
    'After you allow app installs, the update continues by itself.',
  ]),
  ReleaseNote('0.6.1', [
    'Updates are offered on every screen, including sign-in and sign-up.',
  ]),
  ReleaseNote('0.6.0', [
    'Get new versions of inSOL8 inside the app.',
    'Fixed signing in, including Google sign-in.',
  ]),
];
