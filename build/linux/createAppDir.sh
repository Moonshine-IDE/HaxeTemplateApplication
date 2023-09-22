#!/bin/bash

# Usage:
# .build/linux/createAppImage.sh \
# --app-name "AppName" \
# --app-version "1.0.0" \
# --app-icon-name "iconname" \
# --app-categories "Utility;Application;" \
# --bin-paths "/path/to/bin" \
# --lib-paths "/path/to/lib" \
# --share-paths "/path/to/share" \
# --appdir-paths "/path/to/appdir"


# Initialize variables
APP_NAME=""
APP_VERSION=""
APP_ICON_NAME=""
APP_CATEGORIES=""
BIN_PATHS=""
LIB_PATHS=""
SHARE_PATHS=""
APPDIR_PATHS=""

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --app-name) APP_NAME="$2"; shift ;;
        --app-version) APP_VERSION="$2"; shift ;;
        --app-icon-name) APP_ICON_NAME="$2"; shift ;;
        --app-categories) APP_CATEGORIES="$2"; shift ;;
        --bin-paths) BIN_PATHS="$2"; shift ;;
        --lib-paths) LIB_PATHS="$2"; shift ;;
        --share-paths) SHARE_PATHS="$2"; shift ;;
        --appdir-paths) APPDIR_PATHS="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Verify that mandatory arguments are set
if [[ -z $APP_NAME || -z $APP_VERSION || -z $APP_ICON_NAME || -z $APP_CATEGORIES || -z $BIN_PATHS || -z $APPDIR_PATHS ]]; then
    echo "Missing arguments. Usage:"
    echo "--app-name <app-name> --app-version <app-version> --app-icon-name <app-icon-name> --app-categories <app-categories> --bin-paths <bin-paths> --lib-paths <lib-paths> --share-paths <share-paths> --appdir-paths <appdir-paths>"
    exit 1
fi

mkdir -p build/linux/AppDir/usr/bin
mkdir -p build/linux/AppDir/usr/lib
mkdir -p build/linux/AppDir/usr/share

copy_files_to_appdir() {
  IFS=',' read -ra FILES_TO_COPY <<< "$1"
  for file in "${FILES_TO_COPY[@]}"; do
    cp -r "$file" "$2"
  done
}

set -e
copy_files_to_appdir "${BIN_PATHS}" "build/linux/AppDir/usr"
copy_files_to_appdir "${LIB_PATHS}" "build/linux/AppDir/usr/lib"
copy_files_to_appdir "${SHARE_PATHS}" "build/linux/AppDir/usr/share"
copy_files_to_appdir "${APPDIR_PATHS}" "build/linux/AppDir/"

# Create Desktop file
cat << EOF > build/linux/AppDir/${APP_NAME}.desktop
[Desktop Entry]
Name=${APP_NAME}
Exec=${APP_NAME}
Icon=${APP_ICON_NAME}
Type=Application
Categories=${APP_CATEGORIES}
X-AppImage-Name=${APP_NAME}
X-AppImage-Version=${APP_VERSION}
X-AppImage-Arch=x86-64
EOF
chmod a+x build/linux/AppDir/${APP_NAME}.desktop

# Create AppRun file
cat << EOF > build/linux/AppDir/AppRun
#!/bin/bash
        
HERE="\$(dirname "\$(readlink -f "\${0}")")"
cd "\${HERE}/usr/bin"
exec "./${APP_NAME}"
EOF
chmod a+x build/linux/AppDir/AppRun

# Debug output
tree build/linux
echo Desktop:
cat build/linux/AppDir/${APP_NAME}.desktop
echo
echo AppRun:
cat build/linux/AppDir/AppRun
