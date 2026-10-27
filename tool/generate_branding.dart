// Generates the SkillBridge branding PNGs used for the app icon and the
// native splash screen. Run it with:
//
//   flutter test tool/generate_branding.dart
//
// It renders the real widgets from lib/ so the assets always match the
// in-app logo. Output goes to assets/branding/.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbridge/core/app_colors.dart';
import 'package:skillbridge/widgets/brand_logo.dart';

const double _size = 1024;

/// Loads the real Material icon font so glyphs render instead of tofu boxes.
Future<void> _loadIconFont() async {
  final File? font = _findIconFont();
  if (font == null) return;
  final FontLoader loader = FontLoader('MaterialIcons')
    ..addFont(Future<ByteData>.value(
      ByteData.view(font.readAsBytesSync().buffer),
    ));
  await loader.load();
}

File? _findIconFont() {
  const String relative =
      'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  final List<String> candidates = <String>[];

  final String? root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) candidates.add('$root/$relative');

  // Fall back to walking up from the running Dart executable.
  Directory dir = File(Platform.resolvedExecutable).parent;
  for (int i = 0; i < 8; i++) {
    candidates.add('${dir.path}/artifacts/material_fonts/MaterialIcons-Regular.otf');
    final Directory parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  for (final String path in candidates) {
    final File file = File(path);
    if (file.existsSync()) return file;
  }
  return null;
}

Future<void> _capture(WidgetTester tester, Key key, String path) async {
  final RenderRepaintBoundary boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final ui.Image image = await boundary.toImage(pixelRatio: 1);
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  final File file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
}

Widget _framed(Key key, Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(
        key: key,
        child: SizedBox(width: _size, height: _size, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('generate branding assets', (WidgetTester tester) async {
    await _loadIconFont();
    tester.view.physicalSize = const Size(_size, _size);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Full-bleed app icon: navy gradient with the amber handshake mark.
    const Key iconKey = Key('icon');
    await tester.pumpWidget(
      _framed(
        iconKey,
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.navyGradient),
          child: Center(
            child: Icon(
              Icons.handshake_rounded,
              size: 560,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => _capture(tester, iconKey, 'assets/branding/app_icon.png'));

    // 2. Transparent adaptive-icon foreground (handshake with safe-zone padding).
    const Key foregroundKey = Key('foreground');
    await tester.pumpWidget(
      _framed(
        foregroundKey,
        const Center(
          child: Icon(
            Icons.handshake_rounded,
            size: 380,
            color: AppColors.accent,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => _capture(tester, foregroundKey, 'assets/branding/app_icon_foreground.png'),
    );

    // 3. Splash logo: the in-app mark on a white disc, transparent outside.
    const Key splashKey = Key('splash');
    await tester.pumpWidget(
      _framed(
        splashKey,
        Center(
          child: Container(
            padding: const EdgeInsets.all(56),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const BrandLogo(size: 360, showRing: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => _capture(tester, splashKey, 'assets/branding/splash_logo.png'));
  });
}
