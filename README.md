# CyberCafe POS

A complete, offline-first Point-of-Sale application for a combined Cyber Cafe +
Stationery shop, built with **Flutter + Dart**. Runs as a native **Windows
desktop app (.exe)** and a native **Android app (.apk)** from one codebase, with
a local **SQLite** database — no server, no internet connection required for
day-to-day use.

> ⚠️ **Important — read this first.** This project was generated in a sandbox
> that has no Flutter SDK, no Android SDK, no Windows/Visual Studio toolchain,
> and no internet access. The Dart source code below is complete and follows
> Flutter/sqflite/pdf/printing package APIs carefully, but **it has not been
> compiled or run**. Follow the steps below on your own PC to fetch
> dependencies, generate the native platform folders, and build/run it. Treat
> the first `flutter pub get` / `flutter analyze` as your verification step —
> fix any small version-mismatch issues the Flutter/Dart analyzer flags before
> your first real build (package APIs shift slightly between versions).

---

## 1. What's implemented

- **Dashboard**: today's sales, profit, bills, total products, low-stock count,
  total stock value; quick actions to New Sale / Add Product / Inventory /
  Sales History / Reports.
- **Inventory**: add/edit/delete products with image, category, SKU, barcode,
  purchase/selling price, stock qty, min stock, unit, description; search;
  filter by category; manual stock +/- ; automatic low-stock flagging.
- **POS billing screen**: product + service search/grid on one side, live cart
  on the other; quantity edit, discount, payment method (Cash/UPI/Card/Other),
  subtotal/discount/grand total/amount paid/change; one combined bill for
  products **and** cyber-cafe services; on checkout: saves the sale, generates
  a sequential invoice number, deducts stock atomically (DB transaction),
  updates customer lifetime total.
- **Bill/Invoice**: on-screen receipt, Print (system print dialog — works with
  installed Windows printers, including most thermal printers via their
  Windows driver), Save as PDF, Share PDF (Android share sheet).
- **Sales history**: search by invoice #, search by product name, filter by
  date range, view/reprint any bill, void a sale (restores stock).
- **Reports**: daily/weekly/monthly toggle, total sales, gross profit, expenses,
  net profit, sales trend line chart, category-wise pie chart, most-sold
  products, product-wise and service-wise breakdowns, low-stock count.
- **Cyber cafe services**: printing, photocopy, scanning, lamination, passport
  photo, form filling, typing, internet usage, etc. — fully editable, billable
  from the same POS screen as products.
- **Expenses**: category, amount, date, note; factored into Net Profit in
  Reports.
- **Customers**: optional — name, phone, email, address, lifetime purchase
  total; never required for a quick sale.
- **Barcode support**: Android camera scanning (`mobile_scanner`) via a scan
  button on the POS screen; Windows USB HID barcode scanner support (scanners
  that "type" the code + Enter) via an invisible keystroke listener — point a
  USB scanner at a barcode anywhere on the POS screen and it adds the matching
  product to the cart automatically.
- **Backup & restore**: creates a timestamped copy of the SQLite file; on
  Windows, export it to any folder (including a USB drive); on Android, share
  it via any app (email, Drive, Bluetooth, etc.); restore by picking a `.db`
  file, with a confirmation dialog since it replaces all current data. No
  cloud account required.
- **Settings**: shop name/address/phone/GSTIN, currency symbol, invoice
  prefix, printer name, light/dark/system theme.
- **Offline-first**: every one of the above works with zero network access;
  the app never calls out to the internet.

## 2. Architecture

```
lib/
  core/
    db/db_helper.dart       # SQLite schema + transactional sale/void/stock logic
    theme/app_theme.dart    # Colors, light/dark ThemeData
    utils/                  # constants (enums, defaults), formatters
  models/                   # Plain Dart data classes (Product, Sale, ...)
  services/                 # Repositories (DB access) + PdfService + BackupService
  providers/                # ChangeNotifier state (Provider package) per feature
  screens/                  # One folder per feature area
  widgets/                  # Reusable UI: cards, cart panel, barcode listeners
  main.dart                 # Entry point, DB backend selection, MultiProvider, routing
```

Business logic (repositories, `DBHelper`, `PdfService`, `BackupService`) is
kept separate from UI (`screens/`, `widgets/`) and from state (`providers/`),
per the "no giant files" requirement.

The **same** `DBHelper` code runs on both platforms: `main.dart` detects
Windows/Linux/macOS and swaps in `sqflite_common_ffi`'s `databaseFactory`
before anything touches the database; on Android, plain `sqflite` is used
automatically. No platform-specific branching exists anywhere else in the data
layer.

## 3. Prerequisites (on your own machine)

1. **Flutter SDK** (stable channel) — https://docs.flutter.dev/get-started/install
   Run `flutter doctor` and resolve any ❌ items before continuing.
2. **For the Android .apk**: Android Studio + Android SDK (Flutter's installer
   can set this up), a device or emulator with **API 21+**.
3. **For the Windows .exe**: Windows 10/11, **Visual Studio 2022** with the
   *"Desktop development with C++"* workload (required for Flutter's Windows
   desktop toolchain — this is separate from Flutter itself).
4. Enable desktop support once, if not already on:
   ```
   flutter config --enable-windows-desktop
   ```

## 4. First-time setup

From the folder containing this `pubspec.yaml` and `lib/`:

```bash
# 1. Generate the native platform folders (android/, windows/, etc.)
#    Flutter fills these in around your existing lib/ and pubspec.yaml
#    without touching them.
flutter create . --project-name cybercafe_pos --org com.yourshop.cybercafe

# 2. Fetch all packages declared in pubspec.yaml
flutter pub get

# 3. Sanity-check the code before building
flutter analyze
```

If `flutter analyze` reports issues, they'll almost always be either (a) a
package version pinned in `pubspec.yaml` that has since released a breaking
change — bump or pin the version shown in the error, then `flutter pub get`
again — or (b) a platform folder default that needs the manifest edits in
step 5 below.

### 5. One-time manifest edits

**Android** — open `android/app/src/main/AndroidManifest.xml` and add, inside
`<manifest>` (before `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

This is required for the barcode camera scanner (`mobile_scanner`). Also
confirm in `android/app/build.gradle` (or `build.gradle.kts`):

```
minSdkVersion 21   // mobile_scanner requires API 21+
```

**Windows** — no manifest edits are required for the features implemented
here. `sqflite_common_ffi` bundles its own SQLite; `printing`/`pdf` use the
system print dialog so any installed printer driver (including most thermal
printers) works without extra setup.

## 6. Run in development

```bash
# Windows desktop
flutter run -d windows

# Android (device plugged in with USB debugging, or an emulator running)
flutter run -d <device-id>      # `flutter devices` lists available targets
```

## 7. Build the final release files

### Windows — CyberCafePOS.exe

```bash
flutter build windows --release
```

Output folder:
```
build/windows/x64/runner/Release/
```
This folder contains `cybercafe_pos.exe` plus the required `.dll` files —
**copy the whole folder** when distributing (rename the `.exe` if you want the
shop-facing name `CyberCafePOS.exe`), or wrap it with a tool like Inno Setup
if you want a proper installer.

### Android — CyberCafePOS.apk

```bash
# A single APK you can install directly on any Android phone/tablet:
flutter build apk --release

# Or, if you plan to publish to the Play Store instead, use an app bundle:
flutter build appbundle --release
```

Output file:
```
build/app/outputs/flutter-apk/app-release.apk
```
Rename it to `CyberCafePOS.apk` when you hand it to a device, or install
straight from that path via `adb install build/app/outputs/flutter-apk/app-release.apk`.

## 8. Data & backups

The live database lives in the OS's app-support directory (via
`path_provider`), e.g. `%APPDATA%\cybercafe_pos\cybercafe_pos.db` on Windows or
the app's private storage on Android — it survives app restarts and updates.
Use **Settings → Backup & Restore** to copy it out to a USB drive/folder
(Windows) or share it to another app (Android), and to restore it on a new
device. No cloud account is used or required.

## 9. Known limitations / good next steps

- **Thermal printing** here goes through the OS print dialog, which covers the
  vast majority of USB/network thermal printers via their Windows driver. If
  you need raw ESC/POS command printing to a serial/Bluetooth thermal printer
  with no driver, that requires an additional native plugin (e.g.
  `esc_pos_printer`) wired into `PdfService`/`BillViewScreen`.
- **iOS** was not requested and is untouched — `flutter create .` above will
  still scaffold an `ios/` folder in case you want it later; the same Dart
  code should work on it since sqflite supports iOS natively.
- Run `flutter test` after adding widget/unit tests of your own — none are
  bundled here, since none were requested, and untested UI/PDF-rendering code
  is worth eyeballing on a real screen/printer before relying on it in a live
  shop.
