import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Famílias declaradas no `pubspec.yaml`.
abstract final class AppFonts {
  static const display = 'Fraunces';
  static const body = 'DMSans';

  /// Exibe as licenças OFL das fontes embutidas na tela de licenças.
  static void registerLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final (family, file) in const [
        ('Fraunces', 'assets/fonts/OFL-Fraunces.txt'),
        ('DM Sans', 'assets/fonts/OFL-DMSans.txt'),
      ]) {
        yield LicenseEntryWithLineBreaks([
          family,
        ], await rootBundle.loadString(file));
      }
    });
  }
}
