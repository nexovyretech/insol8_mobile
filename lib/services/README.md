# Services

Repositories keep page widgets independent from API and mock data.

- `SubscriptionRepository` resolves and stores an account's selected plan. The
  mock defaults the demo account to Organization and persists onboarding's
  selected plan locally. `ApiSubscriptionRepository` expects `GET` and `POST`
  `/me/subscription` with a `planId` field.
- `BranchRepository` supplies Organization branch records for the Branches
  list and detail pages. Replace `MockBranchRepository` with the team's branch
  API implementation when endpoints are available.
