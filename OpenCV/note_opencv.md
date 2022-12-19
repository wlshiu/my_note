OpenCV
---

# Compile

## Windows

+ Dependency

    - [cmder](https://cmder.app/)
    - CMake-gui
    - [mingw32](https://download.qt.io/development_releases/prebuilt/mingw_32/)
        > for MinGw static libs

        1. [sourceforge](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/)

+ Setep

    - Execute `cmder`
    - set mingw environment in `cmder`
        > `.../mingw32/mingwvars.bat`

        ```bat
        rem mingwvars.bat
        @echo.
        @echo Setting up environment for using MinGW with GCC from %~dp0.
        @set PATH=%~dp0bin;%PATH%
        ```

    - Execute `cmake-gui` in `cmder`

        1. `Where is the source code`
            > Select the source code path

        1. `Where to build the binaries`
            > Select the target output path

        1. Press `Configure`
            > + Select `MinGw Makefile`
            >> check `Specify native compiler`

            > + Set gcc path
            >> `.../mingw32/bin/gcc`

            > + Set g++ path
            >> `.../mingw32/bin/g++`

        1. `CMAKE_MAKE_PROGRAM is not set.`
            > + copy `.../mingw32/bin/mingw32-make` to `.../mingw32/bin/make`
            > + Select CheckBox `Advanced` of CMake-gui
            > + Set `CMAKE_MAKE_PROGRAM` item to `.../mingw32/bin/make`

        1. Press `Generate`
            > configuree end message

            ```
            ...
            Configuring done
            Generating done
            ```

        1. Re-configure compile options
            > Enable/Disable CheckBox items of CMake-gui
            >> reference options

            ```
            -DBZIP2_LIBRARIES=${bzip2_lib_path}/libbz2.a \
            -DBUILD_DOCS=off \
            -DBUILD_SHARED_LIBS=off \
            -DBUILD_FAT_JAVA_LIB=off \
            -DBUILD_TESTS=off \
            -DBUILD_TIFF=on \
            -DBUILD_JASPER=on \
            -DBUILD_JPEG=on \
            -DBUILD_OPENEXR=on \
            -DBUILD_PNG=on \
            -DBUILD_TIFF=on \
            -DBUILD_ZLIB=on \
            -DBUILD_opencv_apps=off \
            -DBUILD_opencv_calib3d=off \
            -DBUILD_opencv_contrib=off \
            -DBUILD_opencv_features2d=off \
            -DBUILD_opencv_flann=off \
            -DBUILD_opencv_gpu=off \
            -DBUILD_opencv_java=off \
            -DBUILD_opencv_legacy=off \
            -DBUILD_opencv_ml=off \
            -DBUILD_opencv_nonfree=off \
            -DBUILD_opencv_objdetect=off \
            -DBUILD_opencv_ocl=off \
            -DBUILD_opencv_photo=off \
            -DBUILD_opencv_python=off \
            -DBUILD_opencv_stitching=off \
            -DBUILD_opencv_superres=off \
            -DBUILD_opencv_ts=off \
            -DBUILD_opencv_video=off \
            -DBUILD_opencv_videostab=off \
            -DBUILD_opencv_world=off \
            -DBUILD_opencv_lengcy=off \
            -DBUILD_opencv_lengcy=off \
            -DWITH_1394=off \
            -DWITH_EIGEN=off \
            -DWITH_FFMPEG=off \
            -DWITH_GIGEAPI=off \
            -DWITH_GSTREAMER=off \
            -DWITH_GTK=off \
            -DWITH_PVAPI=off \
            -DWITH_V4L=off \
            -DWITH_LIBV4L=off \
            -DWITH_CUDA=off \
            -DWITH_CUFFT=off \
            -DWITH_OPENCL=off \
            -DWITH_OPENCLAMDBLAS=off \
            -DWITH_OPENCLAMDFFT=off
            ```

+ Something compile fail

    - `strnlen` not define
        > add function

        ```
        // at .../opencv-3.4.12/modules/core\src/persistence.hpp
        inline size_t strnlen(const char *str, size_t n)
        {
            const char *start = str;

            if( !str || !n )
                return 0;

            while (n-- > 0 && *str)
                str++;

            return str - start;
        }
        ```

    - `fibersapi.h: No such file or directory`
        > Force disable FLS

        ```
        //at ...\opencv-3.4.12\modules\core\src\system.cpp
        #define CV_DISABLE_FLS // added to Force disable FLS

        #if ((_WIN32_WINNT >= 0x0600) && !defined(CV_DISABLE_FLS)) || defined(CV_FORCE_FLS)
          #include <fibersapi.h>
          #define CV_USE_FLS
        #endif
        ```
