---
applyTo: "**/*.swift"
---

# Swift File Rules — seesaw-companion-ios

## Concurrency
- All service types must be declared as `actor`
- All ViewModels must be `@MainActor @Observable final class`
- Use `async/await` — never `DispatchQueue`, never completion handlers
- Use `async let` for parallel independent work within a function

## Naming
- Types: `UpperCamelCase`
- Functions and properties: `lowerCamelCase`
- File name must exactly match the primary type name

## Safety
- Never force-unwrap (`!`) in Services, ViewModels, or Models
- Use `guard let` or `if let` — always handle the nil case
- All throwing functions must be marked `throws` and called with `try`

## Imports
- `Model/` files: zero `import` statements
- `Services/` files: import only the frameworks they directly use
- Never `import UIKit`

## Code Style
- Maximum function length: 30 lines. Extract helpers if longer.
- Add `// MARK: - SectionName` before each logical group of functions
- No inline comments explaining what the code does — write self-documenting code
