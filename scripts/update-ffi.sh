#!/usr/bin/env bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo $THIS_DIR

GENERATED_SWIFT_FILE="$THIS_DIR/../../convex-rs-ffi/generated/swift/Sources/ConvexFFI/ConvexFFI.swift"

if [[ ! -f $GENERATED_SWIFT_FILE ]]; then
    echo "Could not locate generated Swift file at $GENERATED_SWIFT_FILE"
    exit 1
fi

set -euvx

cp "$GENERATED_SWIFT_FILE" "$THIS_DIR/../Sources/ConvexFFI/ConvexFFI.swift"
