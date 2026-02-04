#!/bin/bash

# Witflo Icon Generator
# Regenerates all platform icons from the SVG source

set -e

echo "🎨 Generating Witflo app icons from SVG source..."
echo ""

# Check if rsvg-convert is available
if ! command -v rsvg-convert &> /dev/null; then
    echo "❌ Error: rsvg-convert not found"
    echo "Install with: brew install librsvg"
    exit 1
fi

# Navigate to witflo directory if not already there
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Must run from witflo directory"
    exit 1
fi

SVG_SOURCE="assets/images/logo.svg"

if [ ! -f "$SVG_SOURCE" ]; then
    echo "❌ Error: SVG source not found at $SVG_SOURCE"
    exit 1
fi

echo "📦 Generating base PNG exports..."
rsvg-convert -w 1024 -h 1024 $SVG_SOURCE -o assets/images/logo_1024.png
rsvg-convert -w 512 -h 512 $SVG_SOURCE -o assets/images/logo_512.png
rsvg-convert -w 256 -h 256 $SVG_SOURCE -o assets/images/logo_256.png
rsvg-convert -w 128 -h 128 $SVG_SOURCE -o assets/images/logo_128.png
rsvg-convert -w 64 -h 64 $SVG_SOURCE -o assets/images/logo_64.png
rsvg-convert -w 32 -h 32 $SVG_SOURCE -o assets/images/logo_32.png
rsvg-convert -w 16 -h 16 $SVG_SOURCE -o assets/images/logo_16.png

echo "🍎 Generating macOS icons..."
cp assets/images/logo_1024.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
cp assets/images/logo_512.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
cp assets/images/logo_256.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
cp assets/images/logo_128.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
cp assets/images/logo_64.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
cp assets/images/logo_32.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
cp assets/images/logo_16.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png

echo "📱 Generating iOS icons..."
rsvg-convert -w 20 -h 20 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
rsvg-convert -w 40 -h 40 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
rsvg-convert -w 60 -h 60 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
rsvg-convert -w 29 -h 29 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
rsvg-convert -w 58 -h 58 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
rsvg-convert -w 87 -h 87 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
rsvg-convert -w 40 -h 40 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
rsvg-convert -w 80 -h 80 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
rsvg-convert -w 120 -h 120 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
rsvg-convert -w 120 -h 120 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
rsvg-convert -w 180 -h 180 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
rsvg-convert -w 76 -h 76 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
rsvg-convert -w 152 -h 152 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
rsvg-convert -w 167 -h 167 $SVG_SOURCE -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
cp assets/images/logo_1024.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

echo "🤖 Generating Android icons..."
rsvg-convert -w 48 -h 48 $SVG_SOURCE -o android/app/src/main/res/mipmap-mdpi/ic_launcher.png
rsvg-convert -w 72 -h 72 $SVG_SOURCE -o android/app/src/main/res/mipmap-hdpi/ic_launcher.png
rsvg-convert -w 96 -h 96 $SVG_SOURCE -o android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
rsvg-convert -w 144 -h 144 $SVG_SOURCE -o android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
rsvg-convert -w 192 -h 192 $SVG_SOURCE -o android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

echo "🌐 Generating Web icons..."
cp assets/images/logo_512.png web/icons/Icon-512.png
cp assets/images/logo_512.png web/icons/Icon-maskable-512.png
rsvg-convert -w 192 -h 192 $SVG_SOURCE -o web/icons/Icon-192.png
cp web/icons/Icon-192.png web/icons/Icon-maskable-192.png
cp web/icons/Icon-192.png web/favicon.png

echo ""
echo "✅ All icons generated successfully!"
echo ""
echo "📋 Summary:"
echo "  - macOS: 7 sizes (16px to 1024px)"
echo "  - iOS: 15 sizes (20pt to 1024pt)"
echo "  - Android: 5 densities (mdpi to xxxhdpi)"
echo "  - Web: 2 sizes + favicon"
echo ""
echo "💡 Next steps:"
echo "  1. Rebuild the app to see changes"
echo "  2. Test on each platform"
echo "  3. Commit changes: git add -A && git commit -m 'chore: regenerate app icons'"
