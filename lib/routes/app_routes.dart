/// Named route paths used by navigation throughout the app.
abstract final class AppRoutes {
  static const getStarted = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const managerAuth = '/manager-auth';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const devices = '/devices';
  static const branches = '/branches';
  static const deviceSearch = '/devices/search';
  static const deviceDetails = '/devices/details';
  static const addDevice = '/devices/add';
  static const analytics = '/analytics';
  static const settings = '/settings';
  static const accountProfile = '/settings/account-profile';
  static const managerManagement = '/settings/manager-management';
  static const managerAccess = '/settings/manager-management/access';
  static const addManager = '/settings/manager-management/add';
  static const passwordSecurity = '/settings/password-security';
  static const billingInformation = '/settings/billing-information';
  static const subscriptionUsage = '/settings/subscription-usage';
  static const additionalBranch =
      '/settings/subscription-usage/additional-branch';
  static const additionalDevice =
      '/settings/subscription-usage/additional-device';
  static const additionalBranchSuccess =
      '/settings/subscription-usage/additional-branch/success';
  static const additionalDeviceSuccess =
      '/settings/subscription-usage/additional-device/success';
  static const paymentHistory = '/settings/billing-information/history';
  static const subscriptionLocked = '/subscription/ended';
  static const changePlan = '/settings/change-plan';
  static const preferences = '/settings/preferences';
  static const faqs = '/settings/faqs';
  static const troubleshooting = '/settings/troubleshooting';
  static const userGuide = '/settings/user-guide';
  static const reportIssue = '/settings/report-issue';
  static const aboutUs = '/settings/about-us';
}
