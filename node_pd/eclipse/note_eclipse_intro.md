eclipse_intro
---

[Eclipse IDE for Embedded C/C++ Developers](https://www.eclipse.org/downloads/packages/release/2024-06/r/eclipse-ide-embedded-cc-developers)
> dependency libraries
> + [jdk-8u101-windows-x64](https://www.oracle.com/tw/java/technologies/javase/javase8-archive-downloads.html)
> + [The xPack Windows Build Tools](https://xpack.github.io/dev-tools/windows-build-tools/releases/)

# Eclipse Configurateion

+ Build tool (Globle)
    > `Windows -> Preferences-> tab MCU -> Global Build Tools Path`, 設定全域編譯工具的路徑

    ![eclipse_BuildPath.jpg](./eclipse_BuildPath.jpg)

+ Toolchain
    > `Windows -> Preferences-> tab MCU-> Global RISC-V Toolchains Path`, 設定全域 toolchain 的路徑

    ![eclipse_ToolchainPath.jpg](./eclipse_ToolchainPath.jpg)


+ OpenOCD
    > `Windows -> Preferences-> tab MCU-> Global OpenOCD Path`, 設定全域 openocd 路徑

    ![eclipse_OpenocdPath.jpg](./eclipse_OpenocdPath.jpg)


# Import project


## Existing projects

> `File->Import`

![eclipse_ImportExist.jpg](./eclipse_ImportExist.jpg)

![eclipse_SelDir.jpg](./eclipse_SelDir.jpg)

## Create a new project

> `File -> New -> C/C++ Project`

+ In the C Project window:

    ![eclipse_CProject.jpg](./eclipse_CProject.jpg)

+ Include Existing Directories(Files):
    > + Select the project (依附在哪個 project)
    > + `File -> New -> Folder`

    ![eclipse_IncludeDir.jpg](./eclipse_IncludeDir.jpg)

+ Include Existing Files:
    > + `File -> Import`
    > + Select the directory (加到哪個目錄下)
    > + Select `File System`

    ![eclipse_ImportFiles_1.jpg](./eclipse_ImportFiles_1.jpg)

    > + 勾選 Files
    >> + `From directory` 選擇實體的檔案路徑
    >> + `Into folder` 可以選擇加到哪個目錄下

    ![eclipse_ImportFiles_2.jpg](./eclipse_ImportFiles_2.jpg)


# Tips

+ 目錄結構 project windows-build-tools/releases/
    > Eclipse 中一個工程, package 層次默認為 Flat,
    >> 也就是完成名稱, 但是這種顯示會讓包結構非常複雜, 而且非常不好找,

    > 將其組態為 Hierarchical (即分樹狀層次的)
    >> 路徑在 `Windows->Navigation->Show View Menu->Package Presentation->Hierarchical` 下 (快速鍵 `Ctrl + F10`),
    調整後, 目錄會按資料夾樣式樹狀顯示

+ Font and color
    > `Windows -> Preferences-> tab General -> Appearance -> Colors and Fonts`


# Reference

+ [手把手教你搭建織女星開發板RISC-V開發環境](https://www.cnblogs.com/whik/p/10952292.html)


