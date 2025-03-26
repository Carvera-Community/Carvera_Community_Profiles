#!/usr/bin/env bash

# This is a script intended to one day drive the Fusion post-processor from the
# CLI. Unfortunately it seems more complicated than it need be. You can see some
# of the complexity in invoking this here:
# https://github.com/Autodesk/cam-posteditor/blob/master/vs-code-extension/out/src/extension.js
#
# In the meantime, using the vscode extension remains the best way to write and
# debug. https://github.com/Autodesk/cam-posteditor

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script only works on macOS"
    exit 1
fi

autodesk_path=$(osascript -e 'POSIX path of (path to application "Autodesk Fusion")')

if [ -z "$autodesk_path" ]; then
    echo "Autodesk Fusion not found"
    exit 1
fi

post="${autodesk_path}/Contents/Libraries/Applications/CAM360/post"

if [ ! -f "$post" ]; then
    echo "post not found"
    exit 1
fi

exec "$post" "$@"
