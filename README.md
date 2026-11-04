# BillMate

**Smart Billing for Mechanical Workshops**

BillMate is a professional Android billing application designed for mechanical workshops that repair and service offset printing presses. It replaces manual bill books with a fast, reliable, offline-first mobile application.

---

## Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter SDK | 3.47.7 (stable) |
| Dart SDK | 3.13.5 |
| Android SDK | API 21+ |
| Java / JDK | 17 |

Check your environment:

```bash
flutter doctor -v
```

---

## Getting Started

```bash
# Clone the repository
git clone <repo-url>
cd bill_mate

# Install dependencies
flutter pub get

# Run on a connected Android device or emulator
flutter run
```

---

## Common Commands

```bash
# Run all tests
flutter test

# Run static analysis
flutter analyze

# Format all Dart files
dart format .

# Check outdated packages
flutter pub outdated

# Build a debug APK
flutter build apk --debug

# Build a release APK (requires signing config)
flutter build apk --release
```

---

## Project Architecture

BillMate follows a **feature-oriented, layered architecture** with clear separation between presentation, business logic, and data access.

```
lib/
├── main.dart                  # Entry point — ProviderScope, orientation lock
├── app/
│   ├── bill_mate_app.dart     # Root MaterialApp.router widget
│   ├── config/
│   │   └── app_config.dart   # App identity, company defaults, currency
│   ├── router/
│   │   ├── app_router.dart   # go_router configuration
│   │   └── route_names.dart  # Route path and name constants
│   └── theme/
│       ├── app_colors.dart   # All color constants (no hex in widgets)
│       ├── app_text_styles.dart  # Typography system
│       ├── app_dimensions.dart   # Spacing, radius, icon size tokens
│       └── app_theme.dart    # ThemeData for light and dark modes
├── core/
│   ├── constants/
│   │   └── app_constants.dart  # Shared constants (DB name, limits)
│   ├── errors/
│   │   ├── app_exception.dart  # Typed exception hierarchy
│   │   └── error_handler.dart  # User-facing messages + debug logging
│   ├── utils/
│   │   ├── currency_utils.dart # PKR formatting and parsing
│   │   └── date_utils.dart     # Date formatting utilities
│   └── widgets/
│       ├── app_button.dart         # Primary/outlined/text button
│       ├── app_card.dart           # Consistent card surface
│       ├── app_text_field.dart     # Labeled form text field
│       ├── app_empty_state.dart    # Empty list state widget
│       ├── app_loading_indicator.dart  # Centered and inline loaders
│       └── app_error_view.dart     # Full-page error display
├── features/
│   ├── home/presentation/          # Home screen
│   ├── bills/
│   │   ├── application/            # Bill draft state and date policy
│   │   ├── domain/                 # Draft, item, and exact-paisa money models
│   │   └── presentation/           # New Bill editor and dynamic item table
│   ├── bill_export/
│   │   ├── domain/                 # PDF/JPG generation, file save, print, share
│   │   └── presentation/           # Reusable bill export actions
│   ├── history/presentation/       # Previous Bills and saved bill details
│   └── company_settings/
│       ├── application/            # Company settings providers
│       ├── data/                   # SharedPreferences settings repository
│       ├── domain/                 # Company details model
│       └── presentation/            # Editable Settings screen
└── l10n/                           # (future) Localization ARB files
```

### Layer responsibilities

| Layer | Responsibility |
|---|---|
| **Presentation** (`presentation/`) | Widgets and screens. No business logic. Reads state via Riverpod providers. |
| **Application** (`application/`) | Use-cases and providers. Orchestrates domain and data layers. |
| **Domain** (`domain/`) | Business rules, models, repository interfaces. No Flutter dependencies. |
| **Data** (`data/`) | SQLite repositories, shared_preferences access, external integrations. |
| **Core** | Utilities, error types, shared widgets, constants used across features. |
| **App** | App-wide configuration: theme, routing, root widget. |

Bill-item amounts remain as editable input text in the in-memory draft until
valid. Valid values convert to integer paisa for exact subtotal arithmetic;
unfinished item fields are excluded from the provisional subtotal and clearly
marked. Completed bills, their items, and workshop details are persisted
locally in SQLite.

Saved bills and workshop settings use the same local SQLite database. On web,
SQLite runs through WebAssembly and is stored in the browser's IndexedDB for
that site origin; `web/sqlite3.wasm` and `web/sqflite_sw.js` are required app
assets and are generated with `dart run sqflite_common_ffi_web:setup`.

Phase 6 adds optional fixed-amount or percentage discounts to individual items
and to the bill. Item discounts are applied before the bill discount; all
calculations use integer paisa, with percentage results rounded to the nearest
paisa (half paisa rounds up). Discounts above their applicable subtotal and
malformed values are reported and excluded from provisional totals.

### PDF and JPG exports

The preview and saved-bill details screens can generate searchable, multi-page
PDFs and high-resolution JPGs offline. PDF printing uses the platform print
dialog; sharing uses the native share sheet. On Android, the Save actions use
the system document or folder picker and do not request broad storage access.
Full-bill JPGs are size-limited; page-by-page JPG export is available for longer
bills. Exporting never saves a draft or changes the stored bill.

The PDF embeds the bundled Roboto fonts so currency symbols and common text
render without an internet connection. The font license is included under
`assets/fonts/`.

---

## Design System

| Token | Value |
|---|---|
| Primary color | Deep navy `#0D2137` |
| Secondary color | Professional blue `#1A5276` |
| Accent color | Subtle orange `#E67E22` |
| Background | Soft off-white `#F5F6FA` |
| Surface | White `#FFFFFF` |
| Error | Accessible red `#E53935` |
| Success | Accessible green `#2E7D32` |
| Font | Roboto (system default, high-quality on Android) |

All colors are defined in `app_colors.dart`. No hex literals should appear in widget files.

---

## Development Conventions

1. **No hardcoded colors** — use `AppColors.xyz`.
2. **No hardcoded strings** — company details come from `AppConfig`; route names from `RouteNames`.
3. **No business logic in widgets** — move calculations to domain or application layers.
4. **No database calls in widgets** — use repository interfaces through providers.
5. **Null safety** — avoid `!` assertions; use `??`, `?.`, or conditional rendering.
6. **Error handling** — use typed `AppException` subclasses; present `ErrorHandler.userMessage()` to users.
7. **PKR formatting** — always use `CurrencyUtils.formatAmount()`, never build format strings manually.
8. **Naming** — files use `snake_case`; classes use `PascalCase`; constants use `camelCase`.

---

## Phase Roadmap

| Phase | Feature | Status |
|---|---|---|
| 1 | Project foundation | ✅ Complete |
| 2 | Design system and navigation | ✅ (included in Phase 1) |
| 3 | Home dashboard | ✅ (included in Phase 1) |
| 4 | Bill editor — basic fields | ✅ Complete |
| 5 | Dynamic bill items | ✅ Complete |
| 6 | Discounts and calculations | ✅ Complete |
| 7 | Database and autosave | ✅ Complete |
| 8 | Previous seven bills | ✅ Complete |
| 9 | Physical-style bill preview | ✅ Complete |
| 10 | PDF and JPG export | ✅ Complete |
| 11 | Voice input — basic | ✅ Complete |
| 12 | Voice input — intelligent parsing | 📋 Planned |
| 13 | Validation and error handling | 📋 Planned |
| 14 | UI polish and responsiveness | 📋 Planned |
| 15 | Testing and bug fixing | 📋 Planned |
| 16 | Android release | 📋 Planned |

---

## Application Identity

- **App name:** BillMate
- **Android application ID:** `com.billmate.workshop`
- **Default company:** Babar Machnical Work (exact spelling as supplied)
- **Currency:** PKR (Rs.)
- **Connectivity:** Offline-first — no internet required
- **Authentication:** None required

---

## License

Private application — not for public distribution.
