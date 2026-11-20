import 'package:insol8_mobile/models/dashboard_data.dart';

/// Bridge between `GET /dashboard` payloads and the dashboard UI model.
///
/// The original API fields are still required, but the fields added for the
/// Figma layout accept several common key names so the backend can be wired up
/// without another client release. When the backend omits them, the screenshot
/// design values are used so the dashboard keeps working.
class DashboardPayloadAdapter {
  const DashboardPayloadAdapter();

  DashboardData map(Map<String, dynamic> json) => DashboardData(
    loadsDriedToday: _requiredInt(json, const [
      'loadsDriedToday',
      'loadsToday',
    ]),
    registeredUnits: _requiredInt(json, const [
      'registeredUnits',
      'deviceCount',
    ]),
    activeBranches: _requiredInt(json, const ['activeBranches']),
    totalBranches: _requiredInt(json, const ['totalBranches']),
    energySavedKwh: _requiredDouble(json, const [
      'energySavedKwh',
      'energySaved',
    ]),
    energySavingsEstimatePhp: _requiredDouble(json, const [
      'energySavingsEstimatePhp',
      'energySavingsEstimate',
    ]),
    attentionItems:
        _list(json, const ['attentionItems', 'alerts'])
            ?.map((item) => _attention(item as Map<String, dynamic>))
            .toList(growable: false) ??
        const [],
    runningDryers:
        _int(json, const ['runningDryers', 'dryingNow', 'activeDryers']) ?? 2,
    readyToDry:
        _int(json, const ['readyToDry', 'idleDryers', 'availableDryers']) ?? 4,
    moneyEarnedTodayPhp:
        _double(json, const [
          'moneyEarnedTodayPhp',
          'moneyEarnedToday',
          'earningsTodayPhp',
        ]) ??
        2450,
    dryingJobs:
        _list(json, const ['dryingJobs', 'currentDryingJobs'])
            ?.map((job) => _dryingJob(job as Map<String, dynamic>))
            .toList(growable: false) ??
        defaultDashboardDryingJobs,
    branchActivity:
        _list(json, const ['branchActivity', 'firstRecordedJobs'])
            ?.map((branch) => _branchActivity(branch as Map<String, dynamic>))
            .toList(growable: false) ??
        defaultDashboardBranchActivity,
  );

  Object? _first(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value;
    }
    return null;
  }

  int? _int(Map<String, dynamic> json, List<String> keys) {
    final value = _first(json, keys);
    return value is num ? value.toInt() : null;
  }

  int _requiredInt(Map<String, dynamic> json, List<String> keys) {
    final value = _int(json, keys);
    if (value != null) return value;
    throw FormatException('Dashboard response is missing ${keys.first}.');
  }

  double? _double(Map<String, dynamic> json, List<String> keys) {
    final value = _first(json, keys);
    return value is num ? value.toDouble() : null;
  }

  double _requiredDouble(Map<String, dynamic> json, List<String> keys) {
    final value = _double(json, keys);
    if (value != null) return value;
    throw FormatException('Dashboard response is missing ${keys.first}.');
  }

  String? _string(Map<String, dynamic> json, List<String> keys) {
    final value = _first(json, keys);
    return value is String ? value : null;
  }

  String _requiredString(Map<String, dynamic> json, List<String> keys) {
    final value = _string(json, keys);
    if (value != null) return value;
    throw FormatException('Dashboard response is missing ${keys.first}.');
  }

  List<dynamic>? _list(Map<String, dynamic> json, List<String> keys) {
    final value = _first(json, keys);
    return value is List ? value : null;
  }

  DashboardAttentionItem _attention(Map<String, dynamic> json) =>
      DashboardAttentionItem(
        deviceId: _requiredString(json, const ['deviceId', 'id']),
        deviceName: _requiredString(json, const ['deviceName', 'name']),
        message: _requiredString(json, const ['message', 'description']),
        type: DashboardAttentionType.values.firstWhere(
          (type) => type.name == _string(json, const ['type', 'kind']),
          orElse: () => DashboardAttentionType.connection,
        ),
      );

  DashboardDryingJob _dryingJob(Map<String, dynamic> json) =>
      DashboardDryingJob(
        dryerName: _requiredString(json, const [
          'dryerName',
          'name',
          'deviceName',
        ]),
        loadKg: _requiredDouble(json, const ['loadKg', 'load']),
        remainingMinutes: _requiredInt(json, const [
          'remainingMinutes',
          'remaining',
          'minutesLeft',
        ]),
        status: _string(json, const ['status', 'state']) ?? 'Running',
      );

  DashboardBranchActivity _branchActivity(Map<String, dynamic> json) =>
      DashboardBranchActivity(
        number: _requiredInt(json, const ['number', 'index', 'order']),
        name: _requiredString(json, const ['name', 'branchName']),
        location: _requiredString(json, const ['location', 'address', 'city']),
        time: _requiredString(json, const ['time', 'recordedAt', 'timestamp']),
      );
}
