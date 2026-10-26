# GitHub Actions Publishing Secrets

Configure these secrets in your repository settings:
**Settings** -> **Secrets and variables** -> **Actions** -> **Repository secrets**

| Secret Name | Service | Purpose |
|-------------|---------|---------|
| `NPM_TOKEN` | [npmjs.com](https://www.npmjs.com/settings/tokens) | Publish `@unii/sdk` and `@unii/react` |
| `PYPI_API_TOKEN` | [pypi.org](https://pypi.org/manage/account/token/) | Publish `unii` to PyPI |
| `CARGO_REGISTRY_TOKEN` | [crates.io](https://crates.io/settings/tokens) | Publish `unii` to Crates.io |
| `NUGET_API_KEY` | [nuget.org](https://www.nuget.org/account/apikeys) | Publish `Unii.Sdk` to NuGet |
| `RUBYGEMS_API_KEY` | [rubygems.org](https://rubygems.org/profile/api_keys) | Publish `unii` to RubyGems |
| `MAVEN_CENTRAL_TOKEN` | [central.sonatype.com](https://central.sonatype.com/account) | Central Portal Publishing API Token |
| `GPG_PRIVATE_KEY` | GPG | ASCII armored private key (`gpg --armor --export-secret-keys <ID>`) |
| `GPG_PASSPHRASE` | GPG | Passphrase for private key |
| `PACKAGIST_TOKEN` | [packagist.org](https://packagist.org/profile/) | Packagist API Token |
| `PACKAGIST_USERNAME` | [packagist.org](https://packagist.org/profile/) | Packagist username |

*Note: pub.dev (Dart & Flutter) supports GitHub Actions automatic OIDC publishing without storing long-lived credentials when enabled in pub.dev package settings.*
