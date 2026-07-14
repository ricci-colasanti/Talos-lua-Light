#!/bin/bash
# build.sh - Build Talos-Lua for all platforms

set -e  # Exit on error

echo "════════════════════════════════════════════════════════"
echo "  Building Talos-Lua for All Platforms"
echo "════════════════════════════════════════════════════════"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -f talos-lua-linux talos-lua-windows.exe talos-lua-macos
echo "✅ Clean complete"
echo ""

# Build for Linux (x86_64)
echo "🐧 Building for Linux (x86_64)..."
GOOS=linux GOARCH=amd64 go build -o talos-lua-linux main.go
chmod +x talos-lua-linux
echo "✅ talos-lua-linux"
file talos-lua-linux | head -1
ls -lh talos-lua-linux | awk '{print "   Size: " $5}'
echo ""

# Build for Windows (x86_64)
echo "🪟 Building for Windows (x86_64)..."
GOOS=windows GOARCH=amd64 go build -o talos-lua-windows.exe main.go
echo "✅ talos-lua-windows.exe"
ls -lh talos-lua-windows.exe | awk '{print "   Size: " $5}'
echo ""

# Build for macOS (Intel x86_64)
echo "🍎 Building for macOS (Intel x86_64)..."
GOOS=darwin GOARCH=amd64 go build -o talos-lua-macos main.go
chmod +x talos-lua-macos
echo "✅ talos-lua-macos"
file talos-lua-macos | head -1
ls -lh talos-lua-macos | awk '{print "   Size: " $5}'
echo ""

# Summary
echo "════════════════════════════════════════════════════════"
echo "  ✅ Build Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📦 Binaries created:"
echo "   Linux:   talos-lua-linux"
echo "   Windows: talos-lua-windows.exe"
echo "   macOS:   talos-lua-macos"
echo ""
echo "▶️  To run:"
echo "   Linux:   ./talos-lua-linux config.yaml"
echo "   Windows: talos-lua-windows.exe config.yaml"
echo "   macOS:   ./talos-lua-macos config.yaml"
echo ""
echo "🔍 Verify no external dependencies:"
echo "   Linux:   ldd talos-lua-linux"
echo "   Windows: (check with depends.exe or similar)"
echo "   macOS:   otool -L talos-lua-macos"
