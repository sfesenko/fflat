#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
OUT="$ROOT/build/linux-x64"
LAYOUT="$ROOT/bflat/layouts/linux-glibc-x64"

"$ROOT/build.sh"

if [ ! -x "$LAYOUT/bin/lld" ]; then
    dotnet build "$ROOT/bflat/src/bflat/bflat.csproj" -t:BuildLayouts \
        -p:CompilerHost=linux-glibc-x64 \
        -p:FflatLayoutHost=linux-glibc-x64 \
        -p:CustomAfterMicrosoftCommonTargets="$ROOT/build/fflat-layout.targets"
fi

rm -rf "$OUT"
dotnet publish "$ROOT/src/fflat/fflat.fsproj" \
    -c Release \
    -r linux-x64 \
    --self-contained false \
    -p:PublishSingleFile=true \
    -p:EnableCompressionInSingleFile=true \
    -p:PublishReadyToRun=false \
    -p:DebugType=None \
    -p:DebugSymbols=false \
    -p:CompilerHost=linux-glibc-x64 \
    -o "$OUT"

mkdir -p "$OUT/ref" "$OUT/lib/linux/x64" "$OUT/lib64" "$OUT/bin"
cp -a "$LAYOUT/ref/." "$OUT/ref/"
cp -a "$LAYOUT/lib/linux/x64/." "$OUT/lib/linux/x64/"
cp -a "$LAYOUT/bin/." "$OUT/bin/"
cp -a "$LAYOUT/lib64/." "$OUT/lib64/"
cp -a "$LAYOUT/libjitinterface_x64.so" "$LAYOUT/libclrjit_unix_x64_x64.so" "$OUT/"

rm -f "$OUT/bflat.runtimeconfig.json"

BUILD_OUT="$ROOT/src/fflat/bin/Release/net10.0/linux-x64"
cp -a "$BUILD_OUT/FSharp.Core.dll" "$BUILD_OUT/FSharp.Compiler.Interactive.Settings.dll" "$OUT/"
