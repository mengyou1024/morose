cmake_minimum_required(VERSION 3.5)

project(morose LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Widgets)

set(
    PROJECT_SOURCES
    main.cpp
    morose_config.h
    common/common.h
    common/common.cpp
    resource/morose.qrc
)

add_executable(${PROJECT_NAME} ${PROJECT_SOURCES})
target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Quick Qt6::Widgets)
set_target_properties(${PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE TRUE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Morose)

if (Morose_FOUND)
    if((NOT EXISTS "${CMAKE_SOURCE_DIR}/config/ProductConfig.json") AND (NOT CMAKE_BUILD_TYPE STREQUAL "Release"))
        message(FATAL_ERROR "no ProductConfig.json file please see ${CMAKE_SOURCE_DIR}/config/ProductConfigTemplate.json")
    endif()

    morose_add_environment_config_file(
        TARGET ${PROJECT_NAME}
        DEPLOY "config/DeployConfig.json"
        PRODUCT "config/ProductConfig.json"
        DIST "Config.json"
    )
    morose_auto_release()
endif(Morose_FOUND)
