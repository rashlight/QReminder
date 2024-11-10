cmake_minimum_required(VERSION 3.16)

project(QReminder VERSION 1.0 LANGUAGES CXX)

macro(check_file_exists FILE_DIR)
    if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${FILE_DIR}")
        message(WARNING "File '${CMAKE_CURRENT_SOURCE_DIR}/${FILE_DIR}' does not exist.\nOutput executable functionalities may be missing.")
    endif()
endmacro()

if(CMAKE_SYSTEM_NAME MATCHES "Windows|Darwin|Linux|FreeBSD" AND NOT IOS AND NOT ANDROID)
    set(QRMDR_IS_DESKTOP TRUE)
else()
    set(QRMDR_IS_DESKTOP FALSE)
endif()

if(QRMDR_IS_DESKTOP AND NOT APPLE AND NOT WIN32)
    set(QRMDR_IS_NIX_DESKTOP TRUE)
else()
    set(QRMDR_IS_NIX_DESKTOP FALSE)
endif()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_INSTALL_BINDIR "." CACHE PATH "" FORCE)

# QT CONFIG #
find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Multimedia)
find_package(Qt6 REQUIRED COMPONENTS LinguistTools)

qt_standard_project_setup(REQUIRES 6.5 I18N_TRANSLATED_LANGUAGES ja vi)

if (WIN32)
    set(QRMDR_WIN_RESOURCES "${CMAKE_CURRENT_SOURCE_DIR}/res/win_resources.rc")
    qt_add_executable(appQReminder
        main.cpp
        ${QRMDR_WIN_RESOURCES}
    )
else()
    qt_add_executable(appQReminder
        main.cpp
    )
endif()


qt_add_translations(appQReminder
    TS_FILE_BASE qml
    TS_FILE_DIR i18n
    RESOURCE_PREFIX qt/qml/QReminder/i18n
)

qt_add_qml_module(appQReminder
    URI QReminder
    VERSION 1.0
    QML_FILES
        main.qml
        RESOURCES resources.qrc
        RESOURCES android/AndroidManifest.xml
)

set_target_properties(appQReminder PROPERTIES
    OUTPUT_NAME qreminder
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE_GUI_IDENTIFIER io.github.rashlight.QReminder
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
)

target_link_libraries(appQReminder
    PRIVATE Qt6::Quick Qt6::Multimedia
)

# INSTALL #
include(GNUInstallDirs)
message("Install variables: CMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR} CMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR} CMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}")

# binaries
install(TARGETS appQReminder
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

set(QRMDR_DEPLOY_ARGS "")
if(APPLE)
    set(QRMDR_DEPLOY_ARGS --hardened-runtime)
elseif(WIN32)
    set(QRMDR_DEPLOY_ARGS --no-compiler-runtime --include-soft-plugins)
endif()
qt_generate_deploy_qml_app_script(TARGET appQReminder
    OUTPUT_SCRIPT QRMDR_DEPLOY_SCRIPT
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
    DEPLOY_TOOL_OPTIONS ${QRMDR_DEPLOY_ARGS}
)
install(SCRIPT ${QRMDR_DEPLOY_SCRIPT})

# music
if (QRMDR_IS_DESKTOP)
    check_file_exists("music/happy.wav")
    check_file_exists("music/neutral.wav")
    check_file_exists("music/sad.wav")
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/music" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
    install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/music" DESTINATION "${CMAKE_INSTALL_BINDIR}")
endif()

# license
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE" DESTINATION "${CMAKE_INSTALL_BINDIR}")

# cpack
set(CPACK_PACKAGE_NAME QReminder)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Make quick time events")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/rashlight/QReminder")
set(CPACK_PACKAGE_VENDOR "rashlight")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/res/description.txt")
set(CPACK_PACKAGE_EXECUTABLES qreminder;QReminder)
set(CPACK_PACKAGE_INSTALL_DIRECTORY "${CPACK_PACKAGE_NAME}") # Not all generators use this
set(CPACK_PACKAGE_CHECKSUM "SHA256")
set(CPACK_MONOLITHIC_INSTALL ON)
set(CPACK_VERBATIM_VARIABLES TRUE)

# cpack-generators
set(CPACK_PROJECT_CONFIG_FILE "${CMAKE_CURRENT_SOURCE_DIR}/CPackProjectConfig.cmake")

set(CPACK_DEBIAN_PACKAGE_MAINTAINER "An Van Quoc <andtf2002@gmail.com>")
set(CPACK_DEBIAN_PACKAGE_RELEASE 1)
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>= 2.3.1), libstdc++6 (>= 10.2.1), libgcc-s1 (>= 10.2.1), libxcb-cursor0 (>= 0.1.1)")
set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${CMAKE_CURRENT_SOURCE_DIR}/manynix/deb/postinst;${CMAKE_CURRENT_SOURCE_DIR}/manynix/deb/postrm")

set(CPACK_RPM_PACKAGE_RELEASE 1)
set(CPACK_RPM_PACKAGE_RELEASE_DIST ".el9")
set(CPACK_RPM_PACKAGE_LICENSE "GPLv3+")
set(CPACK_RPM_PACKAGE_REQUIRES "glibc >= 2.34, libstdc++ >= 11.4.1, libgcc >= 11.4.1, xcb-util-cursor >= 0.1.4")
set(CPACK_RPM_PRE_INSTALL_SCRIPT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/manynix/rpm/post")
set(CPACK_RPM_PRE_UNINSTALL_SCRIPT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/manynix/rpm/postun")

set(CPACK_NSIS_DISPLAY_NAME "QReminder")
set(CPACK_NSIS_PACKAGE_NAME "QReminder")
set(CPACK_NSIS_MUI_ICON "${CMAKE_CURRENT_SOURCE_DIR}/res/favicon_installer.ico")
set(CPACK_NSIS_INSTALLED_ICON_NAME "${CMAKE_CURRENT_SOURCE_DIR}/res/favicon.ico")
set(CPACK_NSIS_EXECUTABLES_DIRECTORY ".")
set(CPACK_NSIS_MUI_FINISHPAGE_RUN "qreminder.exe")
set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
set(CPACK_NSIS_CONTACT "andtf2002@gmail.com")
set(CPACK_NSIS_URL_INFO_ABOUT "https://github.com/rashlight/QReminder")
set(CPACK_NSIS_HELP_LINK "https://github.com/rashlight/QReminder/issues")
set(CPACK_NSIS_MANIFEST_DPI_AWARE ON)
set(CPACK_NSIS_BRANDING_TEXT "QReminder - Make quick time events")

# cpackconfig
include(CPack)
