Android Studio
---
[Official User Guide](https://developer.android.com/studio/intro/index.html)
[Github Tutorial](https://github.com/macdidi5/Android-6-Tutorial)

# Portable IDE
    > [Official](https://developer.android.com/studio/index.html) roll to web end, version: No Android SDK, no installer

# Setup

+ Java SE 7+ inatall
    > [Downloads](http://www.oracle.com/technetwork/java/javase/downloads/ )

+ Launch Android Studio
    > ~/android-studio/bin/studio64.exe

    - customize setting
        a. Appearance & Behavior -> Appearance -> Theme select `Darcula`
        b. Editor -> General -> Appearance enable `Show line number` and `Use Block Caret`
        c. Editor -> Colors & Fonts -> Scheme select `Darcula`, press `Save As` for customize

    - Install Android SDK (need to put at the other directory)
        1. press `Configure`
        2. select `SDK manager`
            > auto downlond/install `SDK version`

    - Setup AVD (Android Virtual Device)
        1. press `AVD manager`
        2. `Create Virtual Device`
        3. Select resolution
        4. Select System Image (Download and Install)
            > Recommand 512MB RAM if physical DRAM is 4 GB, and 1 GB RAM if physical DRAM is 8 GB

            > The version of `System Image` NEED to match `SDK version`

            4-1. x86 image
                > If Intel CPU, enable `VT-x` in BIOS (for supporting H/W virtual mechine)

                > If AMD CPU, give up this case

            4-2. arm
                > If AMD CPU, windows enviornment

    - [Genymotion simulator] (https://www.genymotion.com/)
        > install Oracle Virtual Box

        > Need to sign in, and it bases on Oracle Virtual Box (Virtual Box supports AMD-v and intel VT-x)

        1. setup Android Studio
            > File -> Settings -> plugins -> Browse repositories -> search `Genymotion` -> install -> restart

        2. Create simulator
            > Genymotion Device Mamager (on menu bar) -> Press `New` -> sign in and select virtual device type

        3. Start Genymotion simulator

        4. Android Studio press `run app`

# Debug on Real Android Device

+ Usb connection



