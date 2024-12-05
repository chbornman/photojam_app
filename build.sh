#!/bin/bash

# Download Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter 
export PATH="$PATH:$HOME/flutter/bin"

# Run Flutter commands
flutter precache
flutter pub get
flutter build web