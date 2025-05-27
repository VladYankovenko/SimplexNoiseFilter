#!/bin/bash
set -e

METAL_DIR="Sources/SimplexNoiseFilter/kernel"
HEADER_PATH="$METAL_DIR/SimplexNoise.h"

# Пути к исходникам
METAL_SOURCE_1="$METAL_DIR/SimplexNoise.ci.metal"
METAL_SOURCE_2="$METAL_DIR/SphericalNoiseCompute.metal"

# Пути к промежуточным .air файлам
AIR_OUTPUT_1="Sources/SimplexNoiseFilter/resources/SimplexNoise.ci.air"
AIR_OUTPUT_2="Sources/SimplexNoiseFilter/resources/SphericalNoiseCompute.air"

# Итоговый metallib
METALIB_OUTPUT="Sources/SimplexNoiseFilter/resources/SimplexNoise.ci.metallib"

# Очистка старых файлов
rm -f "$AIR_OUTPUT_1" "$AIR_OUTPUT_2" "$METALIB_OUTPUT" 2>/dev/null || true

echo "🛠  Compiling Metal kernels..."

xcrun metal -c \
    -I "$HEADER_PATH" \
    -fcikernel "$METAL_SOURCE_1" \
    -o "$AIR_OUTPUT_1"

xcrun metal -c \
    -I "$HEADER_PATH" \
    -fcikernel "$METAL_SOURCE_2" \
    -o "$AIR_OUTPUT_2"

echo "📦 Packaging Metallib..."

xcrun metallib "$AIR_OUTPUT_1" "$AIR_OUTPUT_2" -o "$METALIB_OUTPUT"

echo "✅ Done! Metallib saved to: $METALIB_OUTPUT"
