# Backend integration handoff

The UI talks to services through repository interfaces. Backend work should
implement these interfaces; screen widgets should not make HTTP requests.

## Service boundaries

| UI area | Interface | Current implementation |
| --- | --- | --- |
| Sign up, verification, login, password reset, Google sign in | `AuthRepository` in `lib/services/auth_repository.dart` | `UnconfiguredAuthRepository` (shows preview messaging; does not call a server) |
| Plans, checkout, branch setup, dryer pairing and setup | `OnboardingRepository` in `lib/services/onboarding_repository.dart` | `MockOnboardingRepository` (local plan fixtures and simulated delays) |

The request data passed to those operations is defined in `lib/models/`.
Implementations should translate those models to the backend's agreed request
and response format. Endpoint paths, authentication tokens, and response
schemas are intentionally not guessed here because the backend contract has
not been supplied.

## Connect implementations

Create concrete classes that implement `AuthRepository` and
`OnboardingRepository`, then inject them at the app composition root. For
example:

```dart
void main() {
  final apiClient = Insol8ApiClient(/* backend configuration */);
  runApp(
    Insol8App(
      authRepository: ApiAuthRepository(apiClient),
      onboardingRepository: ApiOnboardingRepository(apiClient),
    ),
  );
}
```

`Insol8ApiClient` and the `Api*Repository` classes above are examples of the
backend team's implementations; they are not currently part of the app. Keep
the existing default repositories for local UI preview, and inject the API
implementations only after the team confirms its API contract.

## Operations the frontend expects

`AuthRepository` covers sending and resending signup codes, submitting
`SignUpData`, verifying a contact, signing in, password reset, and Google sign
in. `OnboardingRepository` covers loading subscription plans, creating a
checkout session, creating a branch, pairing and verifying a dryer, and saving
device details. The screens already await these methods and show loading or
error feedback around the calls.

The payment success page must only be shown after the payment provider/backend
confirms the transaction. The current mock onboarding flow is for UI preview;
it does not charge a payment method.
