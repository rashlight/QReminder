# Building

## Requirements

For compiling on desktop platforms, you need to install:

 - Qt Framework 6.8.0
 - CMake 3.18 or above
 - Ninja
 - C++ compiler
 - Qt Creator (optional for CLI)
 
Alternatively, use Qt Online Installer and check on necessary parts 
on the Select Components section.
 
Additionally for Android platform, install:

 - Android SDK >= 34, 
 - Android NDK >= 26 or matching Android SDK
 - Android Command-Line Tools, latest
 - JDK 21 or matching Android SDK
 - Android device or Android Emulator loaded with an image
 
Instructions on how to install these software can be found 
on various official documentation for your operating system, 
please reference them for more information.

## Configure & Install

There are two main ways to generate programs and files from source. 
All of them need to have the *Requirements* section completed.

### Qt Creator

Perform instructions to open the project file (CMakeLists.txt), 
build the project with your deploy configuration
and the following depends on your platform:

#### Desktop

Official way is to use the CPack tool if available. 
It will automatically packages necessary components and configurations 
to formats with sensible defaults.
When using this, it is recommended to use the -G flag with ONE generator only.

Here is an example on how to do this on Windows in Powershell:

```powershell
cd path\to\QReminder\build\Desktop_Qt_SomeVersion-SomeBuildType\
cpack -G NSIS      # Generate an installer
cpack -G ZIP       # Generate a portable ZIP file
```

And on Linux in terminal:

```bash
cd path/to/QReminder/build/Desktop_Qt_SomeVersion-SomeBuildType/
cpack -G DEB       // Generate a Debian package        
cpack -G TGZ       // Generate a portable .tar.gz archive
```

Some methods (generators) requires some export tools to start.
See [Packaging With CPack](https://cmake.org/cmake/help/book/mastering-cmake/chapter/Packaging%20With%20CPack.html) 
for more information.

On Windows, please note that only MinGW is confirmed to work.

#### Mobile

##### Android

The android/ folder contains the necessary informations to build for
Android platform. Configuring the project will automatically 
uses this folder for packaging.

For release build, additional keystore needed to be specified. 
Open the Projects tab, then select the Android Kit you are using.
Expand the "Build Android APK" under "Build Steps" by clicking on the "Details" 
button. Fill in the necessary informations in the "Application Signature" box 
and save. DO NOT click on the "Create Templates" button.

See [Deploying an Application on Android
](https://doc.qt.io/qt-6/deployment-android.html) for more information.

### Manual install

Go to the project directory:

```bash
cd path/to/QReminder
```

Use the qt-cmake tool to configure the project (remember to add it to PATH). 
Invoking cmake by itself for cross-compiling is also available, 
but use it with caution as this can conflicts with Qt if not
setup correctly.

Here are some examples:

```powershell
qt-cmake -DCMAKE_PREFIX_PATH=C:/Qt/6.8.0/mingw_64 -S . -B path/to/build # Windows
```

```bash
qt-cmake -DCMAKE_PREFIX_PATH=${HOME}/Qt/6.8.0/gcc_64 -S . -B path/to/build // Linux
```

#### Desktop

Use the CPack tool when possible. 
It will automatically packages necessary components and configurations 
to formats with sensible defaults.
When using this, it is recommended to use the -G flag with ONE generator only.

Examples can be found on the *Qt Creator* section.

However, if CPack cannot be used for some reason, 
you can also generate a binary file by invoking:

```bash
cmake --install . --prefix path/to/export
```

This will save the binary in the path/to/export folder.

By default, this application is built dynamically, not statically. 
Thus, it cannot run by itself. Qt components (such as Qt Quick), libraries and resources 
must be imported to make a complete package.

*On Windows*, navigate to the binary directory and 
use the windeployqt tool:

```powershell
windeployqt --no-compiler-runtime --include-soft-plugins --qmldir path/to/qmldir
```

You can find path/to/qmldir on the QReminder folder on your build folder.

*On Linux or \*nix*, you will need to manually detects the dependencies, versions and import,
then copy them to the search path defined by your dynamic linker (ld.so for Linux). 
If necessary, use qt.conf as needed.

```bash
ldd path/to/binary
objdump -x path/to/binary
```

Alternatively, there are tools that can automatically export to a portable executable (AppImage),
such as [linuxdeployqt](https://github.com/probonopd/linuxdeployqt) (deprecated) 
or [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy) with the [linuxdeploy-plugin-qt](https://github.com/linuxdeploy/linuxdeploy-plugin-qt). 
Be careful using this solution as those methods produce different results than CPack does, and
some may produce incorrect or not working files.

Remember to copy the music folder to the binary folder when complete.

See [Qt for Linux/X11 - Deployment](https://doc.qt.io/qt-6/linux-deployment.html)
and [Using qt.conf](https://doc.qt.io/qt-6/qt-conf.html) for more information.

#### Mobile

##### Android

The ```android/``` folder contains the necessary informations to build for
Android platform. Configuring the project will automatically 
uses this folder for packaging.

After configuring, androiddeployqt can be used to export an Android Package (APK) file.

Here is an example for deploying a release build in Linux:

```bash
export QT_ANDROID_KEYSTORE_PATH=<path_to_keystore_file>
export QT_ANDROID_KEYSTORE_ALIAS=<keystore_alias>
export QT_ANDROID_KEYSTORE_STORE_PASS=<keystore_password>
androiddeployqt \
    --input android-appQReminder-deployment-settings.json \
    --output android-build \
    --android-platform android-35 --gradle \
    --release \
    --sign
```

See [The androiddeployqt Tool](https://doc.qt.io/qt-6/android-deploy-qt-tool.html) 
for more information.

