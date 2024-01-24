set(MOROSE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/resource/img/morose.ico" CACHE STRING "Morose executable icon")
set(MOROSE_OUT_DIR "${CMAKE_SOURCE_DIR}/output" CACHE STRING "Morose output directory")
set(MOROSE_DIST_DIR "${MOROSE_OUT_DIR}/dist" CACHE STRING "Morose dist directory")

set(MOROSE_PLUGINS_DIR "${MOROSE_DIST_DIR}/plugins" CACHE INTERNAL "Morose plugins directory")
set(MOROSE_INSTALL_DIR "${MOROSE_OUT_DIR}/install" CACHE INTERNAL "Morose install output directory")
set(MOROSE_RUNTIME_PLUGINS_DIR "${CMAKE_CURRENT_BINARY_DIR}/plugins" CACHE INTERNAL "runtime plugins directory")
set(MOROSE_PLUGINS_TYPE "GENERIC" "VIEW" CACHE INTERNAL "Morose plugins type")
set(MOROSE_MAIN ${PROJECT_NAME} CACHE INTERNAL "morose excutable file name")
set(MOROSE_PLUGIN_QML_DIRS CACHE INTERNAL "Morose plugin qml directories")
set(MOROSE_UNINSTALL_DELETE CACHE INTERNAL "Morose Inno Setup delete file or directory")

#[[
    获取有关git的相关信息
    `morose_main_setup()`
    软件版本 `APP_VERSION`
    Git仓库地址 `GIT_REPOSITORY`
    Git用户名 `GIT_USER_NAME`
    Git邮箱 `GIT_USER_EMAIL`
    相关变量会保存到 `morose_config.h` 文件中
]]
macro(morose_main_setup)
    find_package(Git QUIET)

    if(GIT_FOUND)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} describe --tags
            OUTPUT_VARIABLE APP_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )

        if(NOT APP_VERSION)
            message(FATAL_ERROR "Git repository must have a tag , use `git tag <tag_name> -m <tag_message>` to create a tag.\n"
                "\te.g.: `git tag v0.0.1 -m \"init\"`\n"
                "the git describe is use for varible `APP_VERSION`"
            )
        else()
            message(STATUS "APP VERSION:" ${APP_VERSION})
        endif()

        execute_process(
            COMMAND ${GIT_EXECUTABLE} remote
            OUTPUT_VARIABLE GIT_REMOTE
            OUTPUT_STRIP_TRAILING_WHITESPACE
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
        execute_process(
            COMMAND ${GIT_EXECUTABLE} remote get-url ${GIT_REMOTE}
            OUTPUT_VARIABLE GIT_REPOSITORY_URL
            OUTPUT_STRIP_TRAILING_WHITESPACE
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
        unset(GIT_REMOTE)
        message(STATUS "GIT_REPOSITORY_URL:${GIT_REPOSITORY_URL}")
        execute_process(
            COMMAND ${GIT_EXECUTABLE} config user.name
            OUTPUT_VARIABLE GIT_USER_NAME
            OUTPUT_STRIP_TRAILING_WHITESPACE
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
        message(STATUS "GIT_USER_NAME:${GIT_USER_NAME}")
        execute_process(
            COMMAND ${GIT_EXECUTABLE} config user.email
            OUTPUT_VARIABLE GIT_USER_EMAIL
            OUTPUT_STRIP_TRAILING_WHITESPACE
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
        message(STATUS "GIT_USER_EMAIL:${GIT_USER_EMAIL}")
    else()
        message(WARNING "no git found, please install git: https://git-scm.com/")
    endif()

    # 搜索inno setup工具
    find_program(ISCC_PATH ISCC)

    if(ISCC_PATH)
        message(STATUS "Detected ISCC_PATH: ${ISCC_PATH}")
    else(ISCC_PATH)
        message(WARNING "no ISCC path found, please install inno setup and add it to path\n see: https://jrsoftware.org/isinfo.php")
    endif(ISCC_PATH)

    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/morose_config.h.in
        ${CMAKE_CURRENT_SOURCE_DIR}/morose_config.h
        @ONLY
    )
endmacro(morose_main_setup)

#[[
    自动打包和生成发布程序
    `morose_auto_release()`
    需要生成 `generate_exe_installer` 目标
]]
function(morose_auto_release)
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        # 生成inno setup 编译脚本
        set(MOROSE_UNINSTALL_DELETE_STRING "")

        foreach(ITEM ${MOROSE_UNINSTALL_DELETE})
            set(MOROSE_UNINSTALL_DELETE_STRING "${MOROSE_UNINSTALL_DELETE_STRING}Type: filesandordirs; Name: \"{app}${ITEM}\"\n")
        endforeach(ITEM ${MOROSE_UNINSTALL_DELETE})

        configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/script/pack-installer.iss.in
            ${CMAKE_CURRENT_SOURCE_DIR}/pack-installer.iss
            @ONLY
        )

        foreach(ITEM ${MOROSE_PLUGINS_TYPE})
            string(TOLOWER ${ITEM} DIR_NAME)
            set(CREATE_DIRS ${CREATE_DIRS} ${MOROSE_PLUGINS_DIR}/${DIR_NAME})
        endforeach(ITEM ${MOROSE_PLUGINS_TYPE})

        # 清除输出
        add_custom_target(
            bundle_clean
            COMMAND ${CMAKE_COMMAND} -E rm -rf "${MOROSE_DIST_DIR}"
            COMMAND ${CMAKE_COMMAND} -E rm -rf "${MOROSE_INSTALL_DIR}"
            COMMENT "clear output directory"
        )

        foreach(ITEM ${MOROSE_PLUGINS_TYPE})
            string(TOLOWER ${ITEM} DIR_NAME)
            set(PLUGIN_DIRS ${PLUGIN_DIRS} ${MOROSE_PLUGINS_DIR}/${DIR_NAME})
        endforeach(ITEM ${MOROSE_PLUGINS_TYPE})

        foreach(ITEM ${MOROSE_PLUGIN_QML_DIRS})
            set(QML_DIRS ${QML_DIRS} "-qmldir=${ITEM}")
        endforeach(ITEM ${MOROSE_PLUGIN_QML_DIRS})

        # 搜索inno setup工具
        find_program(ISCC_PATH ISCC)

        if(ISCC_PATH)
            add_custom_target(
                generate_exe_installer

                # 创建目录 防止某一类插件未使用
                COMMAND ${CMAKE_COMMAND} -E make_directory ${PLUGIN_DIRS}
                COMMAND ${CMAKE_COMMAND} -E make_directory "${MOROSE_DIST_DIR}/FluentUI"

                # 拷贝生成的EXE
                COMMAND ${CMAKE_COMMAND} -E copy
                "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}${CMAKE_EXECUTABLE_SUFFIX}"
                "${MOROSE_DIST_DIR}/${PROJECT_NAME}${CMAKE_EXECUTABLE_SUFFIX}"

                # 执行windeployqt进行打包
                COMMAND ${WINDEPLOYQT_EXECUTABLE}
                --verbose 0
                ${MOROSE_DIST_DIR}
                ${PLUGIN_DIRS}
                ${QML_DIRS}

                # 执行ISCC进行打包
                COMMAND ${ISCC_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/pack-installer.iss" /Q
                DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/pack-installer.iss ${PROJECT_NAME}
                COMMENT "generated executable installer: ${MOROSE_INSTALL_DIR}/${PROJECT_NAME}${CMAKE_EXECUTABLE_SUFFIX}"
            )
        else(ISCC_PATH)
            add_custom_target(
                generate_exe_installer

                # 创建目录 防止某一类插件未使用
                COMMAND ${CMAKE_COMMAND} -E make_directory ${PLUGIN_DIRS}
                COMMAND ${CMAKE_COMMAND} -E make_directory "${MOROSE_DIST_DIR}/FluentUI"

                # 拷贝生成的EXE
                COMMAND ${CMAKE_COMMAND} -E copy
                "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}${CMAKE_EXECUTABLE_SUFFIX}"
                "${MOROSE_DIST_DIR}/${PROJECT_NAME}${CMAKE_EXECUTABLE_SUFFIX}"

                # 执行windeployqt进行打包
                COMMAND echo "windeployqt ..."
                COMMAND ${WINDEPLOYQT_EXECUTABLE}
                --verbose 0
                ${MOROSE_DIST_DIR}
                ${PLUGIN_DIRS}
                ${QML_DIRS}
                
                COMMENT "generated executable installer: ${MOROSE_INSTALL_DIR}/${PROJECT_NAME}${CMAKE_EXECUTABLE_SUFFIX}"
            )
        endif(ISCC_PATH)
    endif(CMAKE_BUILD_TYPE STREQUAL "Release")
endfunction(morose_auto_release)

#[[
    添加qml目录，用于`windeployqt`调用
    `morose_add_qml_dirs(...)`
    如果参数为空则将当前cmake源文件目录添加进去
]]
function(morose_add_qml_dirs)
    if(ARGC EQUAL 0)
        set(MOROSE_PLUGIN_QML_DIRS ${MOROSE_PLUGIN_QML_DIRS} ${CMAKE_CURRENT_SOURCE_DIR} CACHE INTERNAL "Morose plugin qml directories")
    else(ARGC EQUAL 0)
        foreach(ITEM ${ARGV})
            set(MOROSE_PLUGIN_QML_DIRS ${MOROSE_PLUGIN_QML_DIRS} ${CMAKE_CURRENT_SOURCE_DIR}/${ITEM} CACHE INTERNAL "Morose plugin qml directories")
        endforeach(ITEM ${ARGV})
    endif()
endfunction(morose_add_qml_dirs)

#[[
    设置当前项目为插件项目
    `morose_plugin_setup([TYPE] type [TARGET] target)`
    `TYPE` 插件类型，默认为GENERIC 类型必须是`MOROSE_PLUGINS_TYPE`中的一个
    `TARGET` 插件的生成目标，默认为${CMAKE_PROJECT_NAME} 
]]
macro(morose_plugin_setup)
    set(oneValueArgs "TYPE" "TARGET")
    cmake_parse_arguments(SETUP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(SETUP_TYPE)
        if(NOT $<IN_LIST:${SETUP_TYPE}:${MOROSE_PLUGINS_TYPE}>)
            message(FATAL_ERROR "type must one of {${MOROSE_PLUGINS_TYPE}}")
        endif(NOT $<IN_LIST:${SETUP_TYPE}:${MOROSE_PLUGINS_TYPE}>)
    else(SETUP_TYPE)
        set(SETUP_TYPE "GENERIC")
    endif(SETUP_TYPE)

    string(TOLOWER ${SETUP_TYPE} SETUP_TYPE)
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}${PROJECT_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
        "${MOROSE_RUNTIME_PLUGINS_DIR}/${SETUP_TYPE}/${CMAKE_SHARED_LIBRARY_PREFIX}${PROJECT_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
        COMMAND echo "copy plugin [${SETUP_TYPE}/${PROJECT_NAME}] to runtime directory"
        COMMENT "copy plugin [${SETUP_TYPE}/${PROJECT_NAME}] to runtime directory"
    )

    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        add_custom_command(
            TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}${PROJECT_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
            "${MOROSE_PLUGINS_DIR}/${SETUP_TYPE}/${CMAKE_SHARED_LIBRARY_PREFIX}${PROJECT_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
            COMMAND echo "copy plugin [${SETUP_TYPE}/${PROJECT_NAME}] to bundle directory"
            COMMENT "copy plugin [${SETUP_TYPE}/${PROJECT_NAME}] to bundle directory"
        )
    endif(CMAKE_BUILD_TYPE STREQUAL "Release")

    if(NOT SETUP_TARGET)
        message(SEND_ERROR "not set TARGET")
    else(NOT SETUP_TARGET)
        add_dependencies(${MOROSE_MAIN} ${SETUP_TARGET})
        target_include_directories(${SETUP_TARGET} PRIVATE "${CMAKE_CURRENT_LIST_DIR}/../common/interface")
        message(STATUS "MOROSE_MAIN:${MOROSE_MAIN}, add plugin:[${SETUP_TARGET}]")
    endif(NOT SETUP_TARGET)

endmacro(morose_plugin_setup)

#[[
    拷贝文件至运行时目录和打包目录
    `morose_copy([TARGET] target [FILES] ... [DIRS] ... [DIST_DIR] dist_directory [RENAME] rename)`
    `TARGET`: 拷贝依赖
    `FILES`: 文件列表
    `DIRS`: 目录列表
    `DIST_DIR`: 拷贝目标文件夹
    `RENAME`: 重命名拷贝项目, 只有当`FILES`或者`DIRS`只有一个时才可以重命名
]]
function(morose_copy)
    set(oneValueArgs "TARGET" "DIST_DIR" "RENAME")
    set(multiValueArgs "FILES" "DIRS")
    cmake_parse_arguments(COPY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT COPY_TARGET)
        set(COPY_TARGET ${PROJECT_NAME})
    endif(NOT COPY_TARGET)

    if(NOT COPY_DIST_DIR)
        set(COPY_DIST_DIR "/")
    else(NOT COPY_DIST_DIR)
        set(COPY_DIST_DIR "/${COPY_DIST_DIR}/")
    endif(NOT COPY_DIST_DIR)

    if(COPY_FILES)
        # 拷贝文件[列表]
        set(COPY_FILE_STRING "")

        foreach(ITEM ${COPY_FILES})
            get_filename_component(COPY_FILENAME ${ITEM} NAME)

            if(COPY_RENAME)
                list(LENGTH COPY_FILES COPY_FILE_LEN)

                if(COPY_FILE_LEN EQUAL "1")
                    set(COPY_FILENAME ${COPY_RENAME})
                endif(COPY_FILE_LEN EQUAL "1")
            endif(COPY_RENAME)

            list(APPEND COPY_FILE_STRING COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/${ITEM}" "${CMAKE_BINARY_DIR}${COPY_DIST_DIR}${COPY_FILENAME}")

            if(CMAKE_BUILD_TYPE STREQUAL "Release")
                list(APPEND COPY_FILE_STRING COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/${ITEM}" "${MOROSE_DIST_DIR}${COPY_DIST_DIR}${COPY_FILENAME}")
            endif(CMAKE_BUILD_TYPE STREQUAL "Release")
        endforeach(ITEM ${COPY_FILES})

        add_custom_command(
            TARGET ${COPY_TARGET} POST_BUILD

            # 拷贝文件至运行目录
            ${COPY_FILE_STRING}
        )

        if(CMAKE_BUILD_TYPE STREQUAL "Release")
            foreach(ITEM ${COPY_FILES})
                # 添加到inno setup的卸载删除中
                get_filename_component(DELETE_FILE_NAME ${ITEM} NAME)

                if(COPY_RENAME)
                    list(LENGTH COPY_FILES COPY_FILE_LEN)

                    if(COPY_FILE_LEN EQUAL "1")
                        set(DELETE_FILE_NAME ${COPY_RENAME})
                    endif(COPY_FILE_LEN EQUAL "1")
                endif(COPY_RENAME)

                string(FIND "${MOROSE_UNINSTALL_DELETE}" "${COPY_DIST_DIR}${DELETE_FILE_NAME}" pos)

                if(pos EQUAL -1)
                    set(MOROSE_UNINSTALL_DELETE ${MOROSE_UNINSTALL_DELETE} "${COPY_DIST_DIR}${DELETE_FILE_NAME}" CACHE INTERNAL "Morose Inno Setup delete file or directory")
                endif(pos EQUAL -1)
            endforeach(ITEM ${COPY_FILES})
        endif(CMAKE_BUILD_TYPE STREQUAL "Release")
    endif(COPY_FILES)

    if(COPY_DIRS)
        # 拷贝目录[列表]
        set(COPY_DIR_STRING "")

        foreach(ITEM ${COPY_DIRS})
            get_filename_component(COPY_DIRNAME ${ITEM} NAME)

            if(COPY_RENAME)
                list(LENGTH COPY_DIRS COPY_DIR_LEN)

                if(COPY_DIR_LEN EQUAL "1")
                    set(COPY_DIRNAME ${COPY_RENAME})
                endif(COPY_DIR_LEN EQUAL "1")
            endif(COPY_RENAME)

            list(APPEND COPY_DIR_STRING COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_SOURCE_DIR}/${ITEM}" "${CMAKE_BINARY_DIR}${COPY_DIST_DIR}${COPY_DIRNAME}")

            if(CMAKE_BUILD_TYPE STREQUAL "Release")
                list(APPEND COPY_DIR_STRING COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_SOURCE_DIR}/${ITEM}" "${MOROSE_DIST_DIR}${COPY_DIST_DIR}${COPY_DIRNAME}")
            endif(CMAKE_BUILD_TYPE STREQUAL "Release")
        endforeach(ITEM ${COPY_DIRS})

        add_custom_command(
            TARGET ${COPY_TARGET} POST_BUILD

            # 拷贝的是目录
            ${COPY_DIR_STRING}
        )

        if(CMAKE_BUILD_TYPE STREQUAL "Release")
            foreach(ITEM ${COPY_DIRS})
                # 添加到inno setup的卸载删除中
                get_filename_component(DELETE_DIR_NAME ${ITEM} NAME)

                if(COPY_RENAME)
                    list(LENGTH COPY_DIRS COPY_DIR_LEN)

                    if(COPY_DIR_LEN EQUAL "1")
                        set(DELETE_DIR_NAME ${COPY_RENAME})
                    endif(COPY_DIR_LEN EQUAL "1")
                endif(COPY_RENAME)

                string(FIND "${MOROSE_UNINSTALL_DELETE}" "${COPY_DIST_DIR}${DELETE_DIR_NAME}" pos)

                if(pos EQUAL -1)
                    set(MOROSE_UNINSTALL_DELETE ${MOROSE_UNINSTALL_DELETE} "${COPY_DIST_DIR}${DELETE_DIR_NAME}" CACHE INTERNAL "Morose Inno Setup delete file or directory")
                endif(pos EQUAL -1)
            endforeach(ITEM ${COPY_DIRS})
        endif(CMAKE_BUILD_TYPE STREQUAL "Release")
    endif(COPY_DIRS)
endfunction(morose_copy)

#[[
    添加环境配置文件
    `morose_add_environment_config_file([TARGET] target [DEPLOY] deployConfigFile [PRODUCT] productConfigFile [DIST] distName [RUNTIME_USE_PRODUCT])`
    `RUNTIME_USE_PRODUCT`: 在部署环境的运行时使用生产环境配置文件(仅在`CMAKE_BUILD_TYPE`为`Release`时起作用)
    `TARGET`: 依赖目标
    `DEPLOY`: 部署环境的配置文件
    `PRODUCT`: 生产环境的配置文件
    `DIST`: 生成的文件名
]]
function(morose_add_environment_config_file)
    set(options "RUNTIME_USE_PRODUCT")
    set(oneValueArgs "TARGET" "DEPLOY" "PRODUCT" "DIST")
    cmake_parse_arguments(CONF "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    set(CONF_FILE_STRING "")
    get_filename_component(CONF_DEPLOY_FILE_NAME ${CONF_DEPLOY} NAME)
    get_filename_component(CONF_PRODUCT_FILE_NAME ${CONF_PRODUCT} NAME)
    # 拷贝ConfigFile至运行目录
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        if(CONF_RUNTIME_USE_PRODUCT)
            list(APPEND CONF_FILE_STRING COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/${CONF_PRODUCT}" "${CMAKE_BINARY_DIR}/${CONF_DIST}")
        else(CONF_RUNTIME_USE_PRODUCT)
            list(APPEND CONF_FILE_STRING COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/${CONF_DEPLOY}" "${CMAKE_BINARY_DIR}/${CONF_DIST}")
        endif(CONF_RUNTIME_USE_PRODUCT)
    else(CMAKE_BUILD_TYPE STREQUAL "Release")
        list(APPEND CONF_FILE_STRING COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/${CONF_PRODUCT}" "${CMAKE_BINARY_DIR}/${CONF_DIST}")
    endif(CMAKE_BUILD_TYPE STREQUAL "Release")
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        # 拷贝ConfigFile至发布目录
        list(APPEND CONF_FILE_STRING COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/${CONF_DEPLOY}" "${MOROSE_DIST_DIR}/${CONF_DIST}")
        # 添加至卸载的删除路径
        string(FIND "${MOROSE_UNINSTALL_DELETE}" "/${CONF_DIST}" pos)
        if(pos EQUAL -1)
            set(MOROSE_UNINSTALL_DELETE ${MOROSE_UNINSTALL_DELETE} "/${CONF_DIST}" CACHE INTERNAL "Morose Inno Setup delete file or directory")
        endif(pos EQUAL -1)
    endif(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_custom_command(TARGET ${CONF_TARGET} POST_BUILD ${CONF_FILE_STRING})
endfunction(morose_add_environment_config_file)

#[[
    添加子目录的路径, 该函数会遍历目录下所有的文件夹, 如果存在CMakeLists.txt则添加至子目录的构建目录
    `morose_add_subdirectory_path(path)`
    `path`: 子目录路径
]]
function(morose_add_subdirectory_path path)
    file(GLOB SUBPATH "${path}/*")
    foreach(ITEM ${SUBPATH})
        if (IS_DIRECTORY "${ITEM}" AND EXISTS "${ITEM}/CMakeLists.txt")
            file(RELATIVE_PATH ITEM_PATH ${CMAKE_CURRENT_SOURCE_DIR} ${ITEM})
            add_subdirectory(${ITEM_PATH})
        endif(IS_DIRECTORY "${ITEM}" AND EXISTS "${ITEM}/CMakeLists.txt")
    endforeach(ITEM ${ITEM_PATH})
endfunction(morose_add_subdirectory_path path)

set(Morose_FOUND TRUE)
morose_main_setup()
morose_add_subdirectory_path("extensions")
