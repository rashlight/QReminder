# platform-dependent CPack configs
# these will be called AFTER cmake install steps
# see CPACK_PROJECT_CONFIG_FILE for more information

if (CPACK_GENERATOR STREQUAL "DEB")
    set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/qreminder")
elseif(CPACK_GENERATOR STREQUAL "RPM")
    set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/qreminder")
elseif(CPACK_GENERATOR MATCHES "7Z|TBZ2|TGZ|TXZ|TZ|TZST|ZIP")
    set(CPACK_PACKAGING_INSTALL_PREFIX "")
endif()
