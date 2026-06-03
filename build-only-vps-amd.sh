#!/bin/bash

# Build targeting AMD EPYC 7551 (Zen 1) - AVX2 max, no AVX512.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_CPU="$SCRIPT_DIR/src/Native/check_cpu.sh"
CRYPTONOTE_MK="$SCRIPT_DIR/src/Native/libcryptonote/Makefile"
LIBS_SH="$SCRIPT_DIR/src/Miningcore/build-libs-linux.sh"

# Backups
cp "$CHECK_CPU" "$CHECK_CPU.bak"
cp "$CRYPTONOTE_MK" "$CRYPTONOTE_MK.bak"
cp "$LIBS_SH" "$LIBS_SH.bak"

cleanup() {
    cp "$CHECK_CPU.bak" "$CHECK_CPU" && rm "$CHECK_CPU.bak"
    cp "$CRYPTONOTE_MK.bak" "$CRYPTONOTE_MK" && rm "$CRYPTONOTE_MK.bak"
    cp "$LIBS_SH.bak" "$LIBS_SH" && rm "$LIBS_SH.bak"
}
trap cleanup EXIT

# Patch check_cpu.sh to always return false for avx512f
sed -i 's/grep -w .avx512f. \/proc\/cpuinfo >\/dev\/null/false/' "$CHECK_CPU"
sed -i 's/sysctl -n machdep.cpu.features | grep -i avx512f >\/dev\/null/false/' "$CHECK_CPU"

# Patch libcryptonote Makefile to use znver1 instead of native
sed -i 's/-march=native/-march=znver1/g' "$CRYPTONOTE_MK"

# Patch build-libs-linux.sh to use znver1 instead of native for cmake builds
sed -i 's/-DARCH=native/-DARCH=znver1/g' "$LIBS_SH"

(cd src/Miningcore && \
BUILDIR=${1:-../../build} && \
echo "Cleaning build dir $BUILDIR..." && \
rm -rf "$BUILDIR" && \
mkdir -p "$BUILDIR" && \
echo "Building native libs for AMD EPYC (no AVX512)..." && \
bash build-libs-linux.sh "$BUILDIR" && \
echo "Building into $BUILDIR" && \
dotnet publish -c Release --framework net6.0 -o $BUILDIR)
