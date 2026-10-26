# Unii client SDKs

Official client libraries for the Unii API. Each language has its own directory and README.

| Language                   | Directory                  | Package                         |
| -------------------------- | -------------------------- | ------------------------------- |
| Go                         | [go/](go/)                 | `github.com/malviys/unii-go/go` |
| TypeScript                 | [typescript/](typescript/) | `@unii/sdk`                     |
| React                      | [react/](react/)           | `@unii/react`                   |
| Android (Jetpack Compose)  | [android/](android/)       | `io.github.dev-unii:unii-compose` |
| Flutter                    | [flutter/](flutter/)       | `unii_flutter`                  |
| Python                     | [python/](python/)         | `unii`                          |
| Java                       | [java/](java/)             | `io.github.dev-unii:unii-java-sdk` |
| Kotlin                     | [kotlin/](kotlin/)         | `io.github.dev-unii:unii-kotlin`  |
| Dart                       | [dart/](dart/)             | `unii`                          |
| Rust                       | [rust/](rust/)             | `unii`                          |
| C# / .NET                  | [csharp/](csharp/)         | `Unii.Sdk`                      |
| Ruby                       | [ruby/](ruby/)             | `unii`                          |
| PHP                        | [php/](php/)               | `unii/sdk`                      |
| Swift                      | [swift/](swift/)           | `Unii`                          |

## Go development

Run from this repository root:

```bash
cd go
go test ./...
go vet ./...
```

The Go module is now `github.com/malviys/unii-go/go`. Update imports that used `github.com/malviys/unii-go`.

## TypeScript development

Requires Node.js 22 or later. Run from this repository root:

```bash
npm ci
npm run check
npm run build
```

See each language README for its installation and usage instructions.
