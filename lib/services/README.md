# Services

Repositories keep page widgets independent from the API. The app only uses the
API implementations; widget tests inject fakes from `test/support/`.

- `SubscriptionRepository` reads the account's paid plan (`activePlanId`) from
  `GET /onboarding`. The backend records it when a payment is confirmed, so the
  app never stores a plan itself.
- `BranchRepository` reads and creates branches through `/branches`.
