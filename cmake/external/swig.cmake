# Copyright (c) 2016 PaddlePaddle Authors. All Rights Reserve.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Look for system swig
FIND_PACKAGE(SWIG)

IF(NOT ${SWIG_FOUND})
    # build swig as an external project
    INCLUDE(ExternalProject)
    SET(SWIG_SOURCES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/swig)
    SET(SWIG_INSTALL_DIR ${PROJECT_BINARY_DIR}/swig)
    SET(SWIG_TARGET_VERSION "3.0.2")
    SET(SWIG_DOWNLOAD_SRC_MD5 "62f9b0d010cef36a13a010dc530d0d41")
    SET(SWIG_DOWNLOAD_WIN_MD5 "3f18de4fc09ab9abb0d3be37c11fbc8f")

    IF(WIN32)
        # swig.exe available as pre-built binary on Windows:
        ExternalProject_Add(swig
            URL     http://prdownloads.sourceforge.net/swig/swigwin-${SWIG_TARGET_VERSION}.zip
            URL_MD5 ${SWIG_DOWNLOAD_WIN_MD5}
            SOURCE_DIR ${SWIG_SOURCES_DIR}
            CONFIGURE_COMMAND   ""
            BUILD_COMMAND       ""
            INSTALL_COMMAND     ""
        )
        SET(SWIG_DIR ${SWIG_SOURCES_DIR} CACHE FILEPATH "SWIG Directory" FORCE)
        SET(SWIG_EXECUTABLE ${SWIG_SOURCES_DIR}/swig.exe  CACHE FILEPATH "SWIG Executable" FORCE)

    ELSE(WIN32)
        # From PCRE configure
        ExternalProject_Add(pcre
            GIT_REPOSITORY https://github.com/svn2github/pcre.git
            PREFIX ${SWIG_SOURCES_DIR}/pcre
            UPDATE_COMMAND ""
            CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:PATH=${SWIG_INSTALL_DIR}/pcre
        )

        # swig uses bison find it by cmake and pass it down
        FIND_PACKAGE(BISON)

        # From SWIG configure
        ExternalProject_Add(swig
            URL     https://github.com/swig/swig/archive/rel-3.0.10.tar.gz
            PREFIX  ${SWIG_SOURCES_DIR}
            UPDATE_COMMAND ""
            CONFIGURE_COMMAND cd ${SWIG_SOURCES_DIR}/src/swig && ./autogen.sh
            CONFIGURE_COMMAND cd ${SWIG_SOURCES_DIR}/src/swig &&
            env "PCRE_LIBS=${SWIG_INSTALL_DIR}/pcre/lib/libpcre.a \
                ${SWIG_INSTALL_DIR}/pcre/lib/libpcrecpp.a \
                ${SWIG_INSTALL_DIR}/pcre/lib/libpcreposix.a"
            ./configure
                --prefix=${SWIG_INSTALL_DIR}
                --with-pcre-prefix=${SWIG_INSTALL_DIR}/pcre
            BUILD_COMMAND cd ${SWIG_SOURCES_DIR}/src/swig && make
            INSTALL_COMMAND cd ${SWIG_SOURCES_DIR}/src/swig && make install
            DEPENDS pcre
        )

        set(SWIG_DIR ${SWIG_INSTALL_DIR}/share/swig/${SWIG_TARGET_VERSION} CACHE FILEPATH "SWIG Directory" FORCE)
        set(SWIG_EXECUTABLE ${SWIG_INSTALL_DIR}/bin/swig CACHE FILEPATH "SWIG Executable" FORCE)
    ENDIF(WIN32)

    LIST(APPEND external_project_dependencies swig)

ENDIF()

FUNCTION(generate_python_api target_name)
    ADD_CUSTOM_COMMAND(OUTPUT ${PROJ_ROOT}/paddle/py_paddle/swig_paddle.py
                              ${PROJ_ROOT}/paddle/Paddle_wrap.cxx
                              ${PROJ_ROOT}/paddle/Paddle_wrap.h
        COMMAND ${SWIG_EXECUTABLE} -python -c++ -outcurrentdir -I../ api/Paddle.swig
                && mv ${PROJ_ROOT}/paddle/swig_paddle.py ${PROJ_ROOT}/paddle/py_paddle/swig_paddle.py
        DEPENDS ${PROJ_ROOT}/paddle/api/Paddle.swig
                ${PROJ_ROOT}/paddle/api/PaddleAPI.h
                ${external_project_dependencies}
        WORKING_DIRECTORY ${PROJ_ROOT}/paddle
        COMMENT "Generate Python API from swig")
    ADD_CUSTOM_TARGET(${target_name} ALL DEPENDS
                ${PROJ_ROOT}/paddle/Paddle_wrap.cxx
                ${PROJ_ROOT}/paddle/Paddle_wrap.h
                ${PROJ_ROOT}/paddle/py_paddle/swig_paddle.py
                ${external_project_dependencies})
ENDFUNCTION(generate_python_api)
