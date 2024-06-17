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
    src/common/qmltranslator.h
    src/common/qmltranslator.cpp
    resource/morose.qrc
    icon.rc
)

set(QAPPLICATION_CLASS QApplication CACHE STRING "Inheritance class for SingleApplication")

add_executable(${PROJECT_NAME} ${PROJECT_SOURCES})
target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Quick Qt6::Widgets SingleApplication::SingleApplication)
set_target_properties(${PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE TRUE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Morose)

if(Morose_FOUND)
    set(PRODUCT_CONFIG_FILE "config/ProductConfig.json")
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/config/ProductConfig.json")
        message(WARNING "no ProductConfig.json file please see ${CMAKE_SOURCE_DIR}/config/ProductConfigTemplate.json")
        set(PRODUCT_CONFIG_FILE "config/DeployConfig.json")
    endif()

    morose_add_environment_config_file(
        TARGET ${PROJECT_NAME}
        DEPLOY "config/DeployConfig.json"
        PRODUCT ${PRODUCT_CONFIG_FILE}
        DIST "Config.json"
    )
    morose_add_qml_dirs("resource/qml/")
    morose_auto_release()
endif(Morose_FOUND)
