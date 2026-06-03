#!/bin/bash

(cd src/Miningcore && \
BUILDIR=${1:-../../build} && \
echo "Cleaning build dir $BUILDIR..." && \
rm -rf "$BUILDIR" && \
mkdir -p "$BUILDIR" && \
echo "Building into $BUILDIR" && \
dotnet publish -c Release --framework net6.0 -o $BUILDIR)
