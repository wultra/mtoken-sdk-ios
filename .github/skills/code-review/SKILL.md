# Mobile Token SDK iOS code review

Review the PR diff only after verifying the repository, PR target/base branch,
head branch, and current checkout. This is `WultraMobileTokenSDK`, an iOS 13+
Swift 5 SDK distributed by SPM and CocoaPods. Its public library target is
`WultraMobileTokenSDK`; it depends on `PowerAuth2` and
`WultraPowerAuthNetworking`.

## Decision and communication rules

- Approve by default. Raise only a proven new defect with `path:line`, concrete
  impact, and a precise correction. Do not comment on style, formatting, naming,
  CI, tooling, hypothetical risks, or missing tests as a general preference.
- Public API/integration changes need matching public documentation in `docs/` or
  `README.md` and release-visible changes need `docs/Changelog.md`.
- Grammar is in scope only for public docs or public Swift documentation comments,
  and only if the PR base is not `release/*`.
- Do not post to GitHub without explicit user approval. Prefix any proposed
  postable review content with `🤖`.

## Public and protocol surfaces

Review source and binary compatibility in `WultraMobileTokenSDK/WultraMobileToken.swift`
and public models/services under `Inbox/`, `Operations/`, `OIDC/`, and `Push/`.
Important contracts include `WMTInbox`, `WMTOperations`, `WMTOIDC`, `WMTPush`,
their endpoint/request/response models, operation UI data and mobile-token data
builders, QR operation parsing, OIDC configuration/authorization/PKCE models,
push registration parsing, error types, cancellation, and `WPNIntegration`.

Trace network and serialization changes through
`Common/Networking/WMTBaseNetworkingObjects.swift`, `WMTAsyncOperation.swift`,
the `*Endpoints.swift` files, and the request/response `Codable` models. A
finding requires evidence that the changed JSON key, optionality, enum fallback,
date, endpoint path, PowerAuth authentication, token/signature, or error mapping
breaks the service contract. Do not treat an internal refactor as a public break
unless callers or the wire protocol are demonstrably affected.

Security-sensitive review focuses on actual regressions in PowerAuth signatures,
activation attributes, OIDC redirect/state/PKCE handling, token exchange,
operation authorization/rejection data, QR payload parsing, and APNS registration
or signature handling. Also inspect `WMTLogger.swift` and parsing failures for
new disclosure of tokens, authorization data, push identifiers, or server
responses. Report only an introduced, reachable secret leak, authentication
bypass, acceptance of unvalidated protocol data, or incorrect cryptographic flow.

## Asynchrony and lifecycle

The SDK exposes callback-driven service APIs and internal `WMTAsyncOperation`.
For changes in `WMTInbox`, `WMTOperations`, `WMTOIDC`, `WMTPush`, expiration
watching, locks, or networking, verify a demonstrated double/missing callback,
incorrect callback queue, cancellation leak, race, or retained service/delegate.
Where an async/await wrapper is added or changed, it must preserve the callback
result/error/cancellation semantics and resume exactly once; do not request an
async conversion merely for modernity.

## Release, docs, and test evidence

`.prepare-release.json` and `.github/CONTRIBUTING.md` define release metadata:
`WultraMobileTokenSDK.podspec`, `WultraMobileTokenSDK/Info.plist`,
`docs/SDK-Integration.md`, and `docs/Changelog.md`. For a release-to-`develop`
PR, all declared development versions must be `0.0.1-dev`; flag a different
declared version in those version-bearing files. Otherwise, assess version changes
only when the PR is release preparation.

Relevant documentation includes `docs/SDK-Integration.md`, `Example-Usage.md`,
`Error-Handling.md`, and feature guides such as `Using-OIDC-Service.md`,
`Using-Operations-Service.md`, `Using-Push-Service.md`, and
`Using-Inbox-Service.md`. Tests are under `WultraMobileTokenSDKTests`; test
configuration lives in `WultraMobileTokenSDKTests/Configs`. CI uses
`scripts/swiftlint.sh`, `scripts/build.sh`, `scripts/test.sh`, and
`scripts/xcodeselect.sh` with the Xcode project, not `swift test`.
