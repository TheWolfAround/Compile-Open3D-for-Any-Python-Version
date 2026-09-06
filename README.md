# Compile-Open3D-for-Any-Python-Version

The compilation scripts `compile_Open3D.bat` and `compile_Open3D.sh` are self explanatory.
They install dependencies, clone the required repositories, build
[Open3D](https://github.com/isl-org/Open3D) from source and copy the resulting
Python wheel into the working directory.

Both scripts clone the [Open3D](https://github.com/isl-org/Open3D.git) repository and;
- *For Windows* --> [Compile-Vulkan-Equipments-on-Windows](https://github.com/TheWolfAround/Compile-Vulkan-Equipments-on-Windows) script.
- *For Linux* --> [Compile-Vulkan-Equipments-on-Linux](https://github.com/TheWolfAround/Compile-Vulkan-Equipments-on-Linux) script.

[Open3D](https://github.com/isl-org/Open3D.git) compilation script requires, first the Vulkan equipment script to be run
(it provides the `glslangValidator` binary used by Open3D's shader compilation).
The wheel file for the Open3D will be copied into the working dir after a successful compilation.

## Linux requirements (Debian 13 tested)

The script checks and installs the system packages automatically:

- `build-essential`, `cmake`, `git` — standard build toolchain
- `libc++-dev`, `libc++abi-dev` — LLVM's libc++. **Required**: Open3D's Filament
  renderer is prebuilt against libc++, not GCC's libstdc++ (Debian does not
  install it by default).
- `libglu1-mesa-dev` — provides `GL/glu.h`. Despite the name it is only a
  header/link library; it does not affect your GPU driver (NVIDIA or otherwise).
- `libcurl4-openssl-dev`, `libssl-dev` — used with `USE_SYSTEM_CURL=ON` and
  `USE_SYSTEM_OPENSSL=ON` (see troubleshooting below)

Python packages (installed automatically for `$PYTHON`): `dash`, `pybind11-stubgen`.

The interpreter used is `/usr/local/bin/python3` by default; override with
`PYTHON=/path/to/python ./compile_Open3D.sh`.

If you don't know your Python's location, any interpreter name on `PATH` works,
e.g. `PYTHON=python3 ./compile_Open3D.sh` — resolve it first with
`command -v python3`.

## Notes for building for multiple Python versions

The produced wheel is tied to the Python **minor version** (3.x) of the
interpreter used at build time — a wheel built against 3.13 will not load in
3.12 or 3.14. To target another version, rerun the script with that
interpreter:

```bash
PYTHON=/path/to/python3.12 ./compile_Open3D.sh
```

The script already wipes `__build_dir__` at the start of every run
(`rm -rf "$BUILD_DIR"`), so rerunning it with a different `PYTHON` is all you
need — CMake cannot reuse a stale interpreter path. Just note this means every
build is a full rebuild.

## Troubleshooting / findings from a working Debian 13 build

These are the issues hit on the way to a successful build, kept here for
future reference:

1. **`Could not find CPP_LIBRARY using the following names: c++`**
   Filament (Open3D's GUI renderer) requires clang's `libc++`/`libc++abi`.
   Install `libc++-dev libc++abi-dev`.

2. **`libc++ (LLVM) version 19 > 11 includes libunwind ...` warning**
   Expected on Debian 13 and safe to ignore. Only if Python crashes on
   exceptions during visualization would LLVM 11 be needed (not packaged for
   trixie; use `-DBUILD_GUI=OFF` as fallback).

3. **`ninja: error: 'libfilameshio.a' ... missing and no known rule to make it`**
   The prebuilt Filament tarball is downloaded at build time
   (`ninja ext_filament`). If that download is interrupted, Ninja's whole-graph
   pre-flight validation then refuses to run *anything* — including the very
   download step that would fix it. Workaround: `ninja ext_filament`, or as
   here: switch to `Unix Makefiles`, which degrade gracefully. The script now
   uses `-G "Unix Makefiles"`.

4. **`undefined symbol: X509_INFO_free` when importing open3d**
   Upstream bug: bundled static `libcurl.a` is linked *after* the bundled
   BoringSSL archives without `--start-group`, so GNU ld's single pass leaves
   symbols undefined (it surfaces only at `dlopen` time). Works around by
   building with `-D USE_SYSTEM_CURL=ON -D USE_SYSTEM_OPENSSL=ON` and the
   `libcurl4-openssl-dev` / `libssl-dev` packages.

5. **`GL/glu.h: No such file or directory`**
   Install `libglu1-mesa-dev`.

6. **`No module named pybind11_stubgen`** (final packaging step)
   Install `pybind11-stubgen` (and `dash`) into the *same* interpreter the
   module was built against. The script does this automatically.

