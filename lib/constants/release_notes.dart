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
