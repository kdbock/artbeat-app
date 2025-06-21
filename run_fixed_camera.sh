#!/bin/bash

cd "$(dirname "$0")"

echo "Building ARTbeat with fixed camera implementation..."
flutter run --route /fixed-camera
