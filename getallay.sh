#!/usr/bin/sh
# shellcheck shell=dash

## Installer script for Allay.
## See [README](https://github.com/allay-mc/getallay/) for further information.

# MIT License
#
# Copyright (c) 2024 Jonas da Silva
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


set -u

GETALLAY_CPUTYPE="${GETALLAY_CPUTYPE:-}"
## Specify the CPU type for x32 userland systems. Must be either `i686` or `x86_64`.

GETALLAY_PLATFORM="${GETALLAY_PLATFORM:-}"
## Specify the platform (e.g. `aarch64-unknown-linux-gnu`).

GETALLAY_TMPDIR="${GETALLAY_TMPDIR:-.}"
## Specify the directory where the content should be extracted.

GETALLAY_VERSION="${GETALLAY_VERSION:-latest/download}"
## Specify the version of Allay to install. For specifix version, use `download/X.Y.Z`.

GETALLAY_BASE_URL="${GETALLAY_BASE_URL:-https://github.com/allay-mc/allay/releases}"
## Base URL where Allay can be downloaded from.

GETALLAY_ARCHIVE_PREFIX="${GETALLAY_ARCHIVE_PREFIX:-allay}"

GETALLAY_EXECUTABLE_NAME="${GETALLAY_EXECUTABLE_NAME:-allay}"

main() {
  ## The main program.

  local platform
  local archive_ext
  local url
  local path
  local dest
  local exe_ext

  platform="$GETALLAY_PLATFORM"
  if [ -z "$platform" ]; then  
    calculate_platform
    platform="$RESULT"
  fi
  log_info "Your platform is: $platform"
  
  if ! supported "$platform"; then
    panic "Your platform is not supported; install it manually"
  fi

  calculate_archive_extension "$platform"
  archive_ext="$RESULT"

  calculate_executable_extension "$platform"
  exe_ext="$RESULT"

  path="$GETALLAY_TMPDIR/allay-$platform"
  dest="./tmp-allay-$platform"
  url="${GETALLAY_BASE_URL}/${GETALLAY_VERSION}/${GETALLAY_ARCHIVE_PREFIX}-${platform}.${archive_ext}"

  log_info "Downloading Allay... ($url)"
  if check_cmd "curl"; then
    curl -sSfL "$url" -o "$path"
  elif check_cmd "wget"; then
    wget -qO "$path"
  else
    panic "curl or wget must be installed"
  fi

  log_info "Extracting Allay..."
  ensure mkdir "$dest"
  case "$archive_ext" in
    "tar.gz" )
      using tar
      ensure tar -xf "$path" -C "$dest"
      ;;
    "zip" )
      # TODO: test this
      using unzip
      ensure unzip "$path" -d "$dest"
      ;;
    * )
      panic "unreachable"
      ;;
  esac

  ensure mv "$dest"/*/"${GETALLAY_EXECUTABLE_NAME}${exe_ext}" .
  ignore rm "$path" # archive
  ignore rm -rf "$dest" # extracted archive

  log_info "Successfully installed Allay" # TODO: tell path
  log_info "Thank you!"

  # shellcheck disable=SC2016
  log_info 'Make sure to add the path of the executable to your $PATH'

  return 0
}

ensure() {
  ## Ensures a command has run or panic otherwise.
  ##
  ## @param $@  The command.
  ## @panic     The command exited unsuccessful.

  if ! "$@"; then
    panic "command failed: $*"
  fi
}

ignore() {
  ## Emits a warning if the command run unsuccessful.
  ##
  ## @param $@  The command.
  
  if ! "$@"; then
    log_warning "command failed: $*"
  fi
}

supported() {
  ## Returns whether the platform has a prebuilt executable.
  ##
  ## @param $1  The full platform (e.g. `aarch64-unknown-linux-gnu`).
  ## @status 0  The platform is supported.
  ## @status 1  The platform is not supported.

  case "$1" in
    "aarch64-unknown-linux-gnu" |\
    "armv7-unknown-linux-gnueabihf" |\
    "armv7-unknown-linux-musleabi" |\
    "armv7-unknown-linux-musleabihf" |\
    "i686-pc-windows-msvc" |\
    "i868-unknown-linux-gnu" |\
    "powerpc64-unknown-linux-gnu" |\
    "s390x-unknown-linux-gnu" |\
    "x86_64-apple-darwin" |\
    "x86_64-pc-windows-gnu" |\
    "x86_&4-pc-windows-msvc" |\
    "x86_64-unknown-linux-musl" )
      return 0
      ;;
    * )
      return 1
      ;;
  esac
}

panic() {
  ## Exits the program with exit status 1.
  ##
  ## @param $1  (optional) The message to display when exiting.
  
  if test -n "$1"; then
    log_error "$1"
  fi
  exit 1
}

log() {
  ## Low-level implementation for logging.
  ##
  ## @param $1  The label displayed in front of the message.
  ## @param $1  The message to display.
  
  printf "[%s] %s\n" "$1" "$2"
}

log_error() {
  ## Logs an error to the console.
  ##
  ## @param $1  The message to display.
  
  log "ERROR" "$1"
}

log_warning() {
  ## Logs a warning to the console.
  ##
  ## @param $1  The message to display.
  
  log "WARNING" "$1"
}

log_info() {
  ## Logs an info to the console.
  ##
  ## @param $1  The message to display.
  
  log "INFO" "$1"
}

calculate_archive_extension() {
  ## Infers the file extension for the asset (e.g. `.tar.gz`).
  ##
  ## @param $1  The full platform (e.g. `aarch64-unknown-linux-gnu`).
  ## @return    `zip` for Windows targets and `tar.gz` otherwise.
  
  case $1 in
    "i868-pc-windows-msvc" | "x86_64-pc-windows-gnu" | "x86_64-pc-windows-msvc" )
      RESULT="zip"
      ;;
    * )
      RESULT="tar.gz"
      ;;
  esac
}

calculate_executable_extension() {
  ## Infers the file extension for the executable (e.g. `.exe`).
  ##
  ## @param $1  The full platform (e.g. `aarch64-unknown-linux-gnu`).
  ## @return    `.exe` for Windows targets and empty otherwise.
  
  case $1 in
    "i868-pc-windows-msvc" | "x86_64-pc-windows-gnu" | "x86_64-pc-windows-msvc" )
      RESULT=".exe"
      ;;
    * )
      RESULT=""
      ;;
  esac
}

ensure_proc() {
  ## Checks if `/proc` is present.
  ##
  ## @error  `/proc/self/exe` is not present on the system.

  if ! [ -L "/proc/self/exe" ]; then
    panic "Unable to find '/proc/self/exe'. Is '/proc' mounted? Installation cannot proceed without '/proc'."
  fi
}

using() {
  ## Ensures a command exists.
  ##
  ## @param $1  The name of the command.
  ## @error     The command does not exist.

  if ! check_cmd "$1"; then
    panic "missing required command '$1'"
  fi
}

check_cmd() {
  ## Checks if a command exists.
  ##
  ## @param $1  The name of the command.
  ## @status 0  The command exists.
  ## @status 1  The command does not exist.

  command -v "$1" > /dev/null 2>&1
}

calculate_platform() {
  ## Infers the platform running this script.
  ##
  ## @return  The platform of form `cputype-ostype` (e.g. `aarch64-unknown-linux-gnu`)

  local machine
  local kernel
  local os
  local clib
  
  machine="$(uname -m)"
  kernel="$(uname -s)"
  os="$(uname -o)"
  clib="gnu"

  if [ "$kernel" = "Linux" ]; then
    if [ "$os" = "Android" ]; then
      kernel="Android"
    fi
    if ldd --version 2>&1 | grep -q "musl"; then
      clib="musl"
    fi
  fi
  
  if [ "$kernel" = "Darwin" ] && [ "$machine" = "i386" ]; then
    # Darwin `uname -m` lies
    if sysctl hw.optional.x86_64 | grep -q ': 1'; then
      machine="x86_64"
    fi
  fi

  if [ "$kernel" = "Snos" ]; then
    # Both Solaris and illumos presently announce as "SunOS" in "uname -s"
    # so use "uname -o" to disambiguate.  We use the full path to the
    # system uname in case the user has coreutils uname first in PATH,
    # which has historically sometimes printed the wrong value here.
    if [ "$(/usr/bin/uname -o)" = "illumos" ]; then
      kernel="illumos"
    fi
    
    # illumos systems have multi-arch userlands, and "uname -m" reports the
    # machine hardware name; e.g., "i86pc" on both 32- and 64-bit x86
    # systems.  Check for the native (widest) instruction set on the
    # running kernel:
    if [ "$machine" = "i86pc" ]; then
        machine="$(isainfo -n)"
    fi
  fi

  case "$kernel" in
    "Android" )
      kernel="linux-android"
      ;;
    "Linux" )
      ensure_proc
      kernel="unknwon-linux-$clib"
      # TODO: bitness
      ;;
    "FreeBSD" )
      kernel="unknown-freebsd"
      ;;
    "NetBSD" )
      kernel="unknown-netbsd"
      ;;
    "DragonFly" )
      kernel="unknown-dragonfly"
      ;;
    "Darwin" )
      kernel="apple-darwin"
      ;;
    "illumos" )
      kernel="unknown-illumos"
      ;;
    MINGW* | MSYS* | CGYWIN* | "Windows_NT" )
      kernel="pc-windows-gnu"
      ;;
    * )
      panic "unrecognized OS type ('$kernel')"
      ;;
  esac

  case "$machine" in
    "i386" | "i486" | "i686" | "i786" | "x86" )
      machine="i686"
      ;;
    "xscale" | "arm" )
      machine="arm"
      if [ "$machine" = "linux-android" ]; then
        kernel="linux-androideabi"
      fi
      ;;
    "armv6l" )
      machine="arm"
      if [ "$kernel" = "linux-android" ]; then
        kernel="linux-androideabi";
      else
        kernel="${kernel}eabi"
      fi
      ;;
    "armv7l" | "armv8l" )
      machine="armv7"
      if [ "$kernel" = "linux-android" ]; then
        kernel="linux-androideabi"
      else
        kernel="${kernel}eabihf"
      fi
      ;;
    "aarch64" | "arm64" )
      machine="aarch64"
      ;;
    "x86_64" | "x86-64" | "x64" | "amd64" )
      machine="x86_64"
      ;;
    "ppc" )
      machine="powerpc"
      ;;
    "ppc64" )
      machine="powerpc64"
      ;;
    "ppc64le" )
      machine="powerpc64le"
      ;;
    "s390x" )
      machine="s390x"
      ;;
    "riscv64" )
      machine="riscv64gc"
      ;;
    "loongarch64" )
      machine="loongarch64"
      ;;
    * )
      panic "unknown or unsupported CPU type: '$machine'; install it manually"
      ;;       
  esac

  calculate_bitness
  bitness="$RESULT"

  # Detect 64-bit linux with 32-bit userland
  if [ "$kernel" = "unknown-linux-gnu" ] && [ "$bitness" -eq 32 ]; then
    case "$machine" in
      x86_64 )
        if [ -n "${GETALLAY_CPUTYPE:-}" ]; then
          machine="$GETALLAY_CPUTYPE"
        else
          # TODO
          panic
        fi
        ;;
    "powerpc64" )
      machine="powerpc"
      ;;
    "aarch64" )
      machine="arm7"
      if [ "$kernel" = "linux-android" ]; then
        kernel="linux-andoideabi"
      else
        kernel="${kernel}eabihf"
      fi
      ;;
    "riscv64gc" | "mips64" )
      panic "riscv64 and mips64 with 32-bit userland unsupported"
      ;;
    esac
  fi

  RESULT="${machine}-${kernel}"
}

calculate_bitness() {
  ## Infers the bitness.
  ##
  ## @return  `"32"` or `"64"`.
  ## @error   Failed to detect the bitness.

  using head

  local current_exe_head
  current_exe_head="$(head -c 5 /proc/self/exe)"
  if [ "$current_exe_head" = "$(printf '\177ELF\001')" ]; then
    RESULT=32
  elif [ "$current_exe_head" = "$(printf '\177ELF\002')" ]; then
    RESULT=64
  else
    panic "unknown platform bitness"
  fi
}

main "$@" || exit 1
