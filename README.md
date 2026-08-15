# Upload to App Dropper

Send an `.apk` or `.ipa` to [App Dropper](https://appdropper.io) from a GitHub Actions workflow, and get a shareable install link — optionally posted straight onto the pull request with a scannable QR code.

## Quick start

```yaml
- name: Upload to App Dropper
  uses: appdropper-io/upload-action@v1
  with:
    file: build/app/outputs/flutter-apk/app-release.apk
    token: ${{ secrets.APPDROPPER_TOKEN }}
    release-notes: ${{ github.event.head_commit.message }}
```

Generate the token under **Settings → API tokens** in your App Dropper dashboard, then add it as a repository secret named `APPDROPPER_TOKEN`.

## Full example

```yaml
name: Beta build

on:
  push:
    branches: [main]
  pull_request:

# Needed for the PR comment. Without it, the upload still succeeds and the
# comment step is skipped.
permissions:
  contents: read
  pull-requests: write

jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter build apk --release

      - name: Upload to App Dropper
        id: appdropper
        uses: appdropper-io/upload-action@v1
        with:
          file: build/app/outputs/flutter-apk/app-release.apk
          token: ${{ secrets.APPDROPPER_TOKEN }}

      - run: echo "Install at ${{ steps.appdropper.outputs.install-url }}"
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `file` | yes | — | Path to the `.apk` or `.ipa`, relative to the workspace |
| `token` | yes | — | App Dropper API token, from a repository secret |
| `release-notes` | no | head commit message | Notes shown to testers on the install page |
| `tag` | no | `beta` | Label for the build, e.g. `nightly` |
| `comment-on-pr` | no | `true` | Post the install link as a pull-request comment |
| `timeout` | no | `600` | Seconds to wait for processing before failing |
| `cli-version` | no | `1` | Version of the `appdropper` npm package to run |
| `api-url` | no | — | Override the API base URL (self-hosted only) |

## Outputs

| Output | Description |
|---|---|
| `install-url` | Public install link for the uploaded build |
| `build-id` | Identifier of the build that was created |
| `qr-url` | PNG QR code pointing at the install link |

## Pull-request comments

On a `pull_request` event the action posts a comment with the install link, the artifact name, the commit SHA and a QR image — then **edits that same comment** on later pushes rather than adding another.

Two requirements:

- `permissions: pull-requests: write` on the workflow or job.
- A pull request from a branch in the **same repository**. GitHub withholds secrets from forked PRs and gives them a read-only token, so neither the upload nor the comment can run there. That's a GitHub security boundary, not an App Dropper limitation.

Set `comment-on-pr: false` to turn comments off. The job summary — same link, same QR code, on the workflow run page — is always written and needs no permissions.

## Only upload when it matters

Uploads count against your plan's hourly limit and storage, so most teams gate them:

```yaml
- name: Upload to App Dropper
  if: >-
    github.ref == 'refs/heads/main' ||
    contains(github.event.pull_request.labels.*.name, 'needs-testing')
  uses: appdropper-io/upload-action@v1
  with:
    file: build/app/outputs/flutter-apk/app-release.apk
    token: ${{ secrets.APPDROPPER_TOKEN }}
```

## Without the action

This action is a thin composite wrapper around the [`appdropper` CLI](https://www.npmjs.com/package/appdropper), so calling the CLI directly is equally supported — you lose the PR comment and gain nothing to maintain:

```yaml
- name: Upload to App Dropper
  env:
    APPDROPPER_TOKEN: ${{ secrets.APPDROPPER_TOKEN }}
  run: npx appdropper upload build/app/outputs/flutter-apk/app-release.apk
```

Step outputs still work — the CLI writes them to `$GITHUB_OUTPUT` itself.

## Docs

- [GitHub Actions guide](https://appdropper.io/help/github-actions)
- [CI/CD setup guide](https://appdropper.io/help/ci-cd-uploads)
- [REST API reference](https://appdropper.io/help/api)

## License

MIT
