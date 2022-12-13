#!/bin/sh
source bash_files/ask.sh

function compile_modules {
  echo "compiling modules"
  csc -emit-all-import-libraries -explicit-use listicles.scm
  csc -emit-all-import-libraries -explicit-use interrupt-database.scm
  csc -emit-all-import-libraries -explicit-use uri-tools.scm
  csc -emit-all-import-libraries -explicit-use hey-dates.scm
  csc -emit-all-import-libraries -explicit-use x-by-hour-report.scm
  csc -emit-all-import-libraries -explicit-use interrupts-by-day-report.scm
  csc -emit-all-import-libraries -explicit-use fmt-better.scm
  csc -emit-all-import-libraries -explicit-use who-list.scm
}
function copy_modules_into_libs {
  if [ ! -d hey_libs ]; then
    echo "Please run './build.sh libraries' first to create the hey_libs"
    echo "directory and install the 3rd party libraries."
    exit 1
  fi
  cp listicles hey_libs/
  cp uri-tools hey_libs/
  cp hey-dates hey_libs/
  cp interrupt-database hey_libs/
  cp x-by-hour-report hey_libs/
  cp interrupts-by-day-report hey_libs/
  cp fmt-better hey_libs/
  cp who-list hey_libs/
}
function build_libraries {
  if [ -d "hey_libs" ]; then
      rm -rf hey_libs
  fi
  mkdir -p hey_libs
  chicken-install fmt
  chicken-install -deploy -p hey_libs/ fmt
  chicken-install loops
  chicken-install -deploy -p hey_libs/ loops
  chicken-install sql-de-lite
  chicken-install -deploy -p hey_libs/ sql-de-lite
  chicken-install condition-utils
  chicken-install -deploy -p hey_libs/ condition-utils
  chicken-install error-utils
  chicken-install -deploy -p hey_libs/ error-utils
  chicken-install srfi-19
  chicken-install -deploy -p hey_libs/ srfi-19
  chicken-install srfi-13
  chicken-install -deploy -p hey_libs/ srfi-13
  chicken-install srfi-1
  chicken-install -deploy -p hey_libs/ srfi-1
  chicken-install pathname-expand
  chicken-install -deploy -p hey_libs/ pathname-expand
  chicken-install numbers
  chicken-install -deploy -p hey_libs/ numbers
  chicken-install json-abnf
  chicken-install -deploy -p hey_libs/ json-abnf
  chicken-install json
  chicken-install -deploy -p hey_libs/ json
  chicken-install uri-common
  chicken-install -deploy -p hey_libs/ uri-common
  chicken-install shell
  chicken-install -deploy -p hey_libs/ shell
  chicken-install http-client
  chicken-install -deploy -p hey_libs/ http-client
  brew install openssl
  export CPATH=$CPATH:/usr/local/opt/openssl/include
  export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib
  chicken-install openssl
  chicken-install -deploy -p hey_libs/ openssl
}
function build_local {
  echo "compiling hey.scm"
  csc hey.scm
  if [ -e hey_libs ]; then
    cp hey hey_libs/
  fi
}

function build_tarball {
  compile_modules
  build_local
  version=$(./hey --version | grep version | sed -e "s/.* //")
  echo "version: $version"
  tempdir="tarball_temp"
  if [ -e $tempdir ]; then 
    rm -rf $tempdir
  fi
  hey_version_name="hey-$version"
  hey_tempdir="$tempdir/$hey_version_name"
  tarball="$hey_version_name.tar.gz"
  echo "building $tarball"
  mkdir -p $hey_tempdir
  cp -r hey_libs/* $hey_tempdir/
  cd $tempdir
  tar -czf $tarball $hey_version_name
  mv $tarball ../
  cd ../
  rm -rf $tempdir
  if ask "upload to interrupttracker.com?"; then
    scp $tarball interrupttracker.com:interrupttracker.com/
  fi
}

function build_mac {
  compile_modules
  build_local
  copy_modules_into_libs
  cp default.db hey_libs/
  rm -rf hey.app
  csc -deploy -gui hey.scm
  cp -r hey_libs/* hey.app/Contents/MacOS/
  rm hey.app/Contents/Resources/CHICKEN.icns
  cp images/iconset.icns hey.app/Contents/Resources/CHICKEN.icns
  # perl -pi -e 's/CHICKEN.icns/iconfile.icns/g' hey.app/Contents/Info.plist

  
  if ask "replace /Appications/hey.app?"; then
    rm -rf /Applications/hey.app
    cp -r hey.app /Applications/
    echo "replaced."
  else
    echo "ok. I won't."
  fi

  if ask "Install cli helper tool to execute it from anywhere?"; then
    source bash_files/install_cli_tool.sh
    eval "$(cat "bash_files/where_is_it.sh")"
    install_cli_tool $EXPECTED_PATH
  fi
}

deploy_type=$1
if [ "$deploy_type" = "" ]; then
  echo "deploy type? [libraries|local|mac|linux|dmg|modules|tarball]: "
  read deploy_type
fi

if [ "$deploy_type" = "libraries" ]; then
  if ask "this will delete & rebuild the hey_libs dir if present. Are you sure?"; then
    build_libraries
  fi
elif [ "$deploy_type" = "local" ]; then
  compile_modules
  build_local
elif [ "$deploy_type" = "modules" ]; then
  compile_modules
elif [ "$deploy_type" = "mac" ]; then
  build_mac
elif [ "$deploy_type" = "tarball" ]; then
  build_tarball
elif [ "$deploy_type" = "linux" ]; then
  compile_modules
  copy_modules_into_libs
  build_local
  cp hey hey_libs/
  source bash_files/install_cli_tool.sh
  eval "$(cat "bash_files/where_is_it.sh")"
  install_cli_tool $EXPECTED_PATH
elif [ "$deploy_type" = "dmg" ]; then
  build_mac
  csc -deploy hey.scm
  if [ -e hey_libs ]; then
    cp hey/hey hey_libs/
    rm -rf hey
  fi

  mkdir -p html/downloads
  rm html/downloads/hey.dmg
  appdmg appdmg.json html/downloads/hey.dmg
fi


