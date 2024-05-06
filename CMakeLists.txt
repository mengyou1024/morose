cmake_minimum_required(VERSION 3.20)

project(morose LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Widgets)

set(
    PROJECT_SOURCES
    src/main.cpp
    src/morose_config.h
    src/common/common.h
    src/common/common.cpp
    resource/morose.qrc
    icon.rc
)

add_executable(${PROJECT_NAME} ${PROJECT_SOURCES})
target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Quick Qt6::Widgets)
set_target_properties(${PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE TRUE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Morose)

morose_add_qml_dirs("resource/qml/")

if (Morose_FOUND)
    if((NOT EXISTS "${CMAKE_SOURCE_DIR}/config/ProductConfig.json") AND (NOT CMAKE_BUILD_TYPE STREQUAL "Release"))
        message(WARNING "no ProductConfig.json file please see ${CMAKE_SOURCE_DIR}/config/ProductConfigTemplate.json")
    else()
        morose_add_environment_config_file(
            TARGET ${PROJECT_NAME}
            DEPLOY "config/DeployConfig.json"
            PRODUCT "config/ProductConfig.json"
            DIST "Config.json"
        )
    endif()
    morose_auto_release()
endif(Morose_FOUND)
