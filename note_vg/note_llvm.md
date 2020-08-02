LLVM
---





# [Build LLVM 3.7 with MinGW w64, MSYS2, CMake](https://github.com/valtron/llvm-stuff/wiki/Build-LLVM-3.7-with-MinGW-w64,-MSYS2,-CMake)

+ Install [MSYS2](http://msys2.github.io/)
+ Install [CMake](https://cmake.org/download)
+ Download LLVM source and uncompress to folder `$LLVMSRC`
+ Create folder `$LLVMBUILD` and create `build.sh` with contents:

```
# build.sh
PATH="/c/Windows/system32:/c/MinGW/mingw32/bin:/c/Program Files (x86)/CMake/bin"

LLVMSRC="$LLVMSRC"
LLVMINS="/c/LLVM/llvm-3.7"

cmake \
	-G "MinGW Makefiles" \
	-DCMAKE_INSTALL_PREFIX="$LLVMINS" \
	-DLLVM_TARGETS_TO_BUILD="X86;CppBackend" \
	-DLLVM_INCLUDE_TESTS=OFF \
	-DLLVM_ENABLE_CXX1Y=ON \
	"$LLVMSRC"

cmake --build .
cmake --build . --target install
```

+ Open `msys2_shell.bat` (it's in the folder where you installed msys64)
+ cd into `$LLVMBUILD`
+ `sh build.sh`


## Notes

+ MSYS2 isn't strictly necessary; if you don't want to install it, translate `build.sh` to a batch file and run it in regular windows command prompt.
MSYS2 comes with a package manager (pacman) to install UNIX tools like flex and bison.

+ `build.sh` sets some options; customize to your own needs; they're documented [here](http://llvm.org/docs/CMake.html#llvm-specific-variables);
you can find the list of backends in `$LLVMSRC/CMakeLists.txt`, search for `set(LLVM_ALL_TARGETS`.

## Problems with LLVM_BUILD_LLVM_DYLIB

If you want to build libLLVM.dll using the instructions above, adding `LLVM_BUILD_LLVM_DYLIB:ON` will likely fail.
Use this guide to build it manually.


# reference

+ [LLVM 寫一個 pass - 教學入門篇](https://kitoslab.blogspot.com/2012/10/llvm-pass.html)
+ [LLVM第一彈——介紹及環境搭建(截止2018/9/14可用)](https://www.itread01.com/content/1544368690.html)
+ [編譯器 LLVM 淺淺玩](https://medium.com/@zetavg/%E7%B7%A8%E8%AD%AF%E5%99%A8-llvm-%E6%B7%BA%E6%B7%BA%E7%8E%A9-42a58c7a7309)

