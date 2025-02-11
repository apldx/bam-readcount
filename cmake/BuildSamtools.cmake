cmake_minimum_required(VERSION 2.8)

set(SAMTOOLS_VERSION 1.10)

set(SAMTOOLS_ROOT ${CMAKE_BINARY_DIR}/vendor/samtools-${SAMTOOLS_VERSION})
set(SAMTOOLS_LOG ${CMAKE_BINARY_DIR}/cmake_samtools_build.log)
set(HTSLIB_LOG ${CMAKE_BINARY_DIR}/cmake_htslib_build.log)
set(SAMTOOLS_LIB ${SAMTOOLS_ROOT}/${CMAKE_FIND_LIBRARY_PREFIXES}bam${CMAKE_STATIC_LIBRARY_SUFFIX})
#set(SAMTOOLS_BIN ${SAMTOOLS_ROOT}/samtools)

set(HTSLIB_ROOT ${SAMTOOLS_ROOT}/htslib-${SAMTOOLS_VERSION})
set(HTSLIB_LIB ${HTSLIB_ROOT}/${CMAKE_FIND_LIBRARY_PREFIXES}hts${CMAKE_STATIC_LIBRARY_SUFFIX})

cmake_print_variables(SAMTOOLS_ROOT)
cmake_print_variables(SAMTOOLS_LIB)
cmake_print_variables(HTSLIB_LIB)

set(ZLIB_ROOT ${CMAKE_BINARY_DIR}/vendor/zlib)
set(ZLIB_SRC ${CMAKE_BINARY_DIR}/vendor/zlib-src)
set(ZLIB_INCLUDE_DIRS ${ZLIB_ROOT}/include)
set(ZLIB_LIBRARIES ${ZLIB_ROOT}/lib/${CMAKE_FIND_LIBRARY_PREFIXES}z${CMAKE_STATIC_LIBRARY_SUFFIX})
ExternalProject_Add(
  zlib
  BUILD_BYPRODUCTS ${ZLIB_LIBRARIES}
  ARGS
    URL ${CMAKE_SOURCE_DIR}/vendor/zlib-1.2.11.tar.gz
    SOURCE_DIR ${ZLIB_SRC}
    BINARY_DIR ${ZLIB_SRC}
    CONFIGURE_COMMAND ./configure --prefix=${ZLIB_ROOT}
    BUILD_COMMAND make
    INSTALL_COMMAND make install
)

set(XZ_ROOT ${CMAKE_BINARY_DIR}/vendor/xz)
set(XZ_SRC ${CMAKE_BINARY_DIR}/vendor/xz-src)
set(XZ_INCLUDE_DIRS ${XZ_ROOT}/include)
set(XZ_LIBRARIES ${XZ_ROOT}/lib/${CMAKE_FIND_LIBRARY_PREFIXES}lzma${CMAKE_STATIC_LIBRARY_SUFFIX})
ExternalProject_Add(
  xz
  BUILD_BYPRODUCTS ${XZ_LIBRARIES}
  ARGS
    URL ${CMAKE_SOURCE_DIR}/vendor/xz-5.2.4.tar.gz
    SOURCE_DIR ${XZ_SRC}
    BINARY_DIR ${XZ_SRC}
    CONFIGURE_COMMAND ./configure --prefix=${XZ_ROOT}
    BUILD_COMMAND make
    INSTALL_COMMAND make install
)

set(BZIP2_ROOT ${CMAKE_BINARY_DIR}/vendor/bzip2)
set(BZIP2_INCLUDE_DIRS ${BZIP2_ROOT})
set(BZIP2_LIBRARIES ${BZIP2_ROOT}/${CMAKE_FIND_LIBRARY_PREFIXES}bz2${CMAKE_STATIC_LIBRARY_SUFFIX})
ExternalProject_Add(
  bzip2
  BUILD_BYPRODUCTS ${BZIP2_LIBRARIES}
  ARGS
    URL ${CMAKE_SOURCE_DIR}/vendor/bzip2-1.0.8.tar.gz
    SOURCE_DIR ${BZIP2_ROOT}
    BINARY_DIR ${BZIP2_ROOT}
    CONFIGURE_COMMAND echo "Building bzip2 library"
    BUILD_COMMAND make
    INSTALL_COMMAND true
)

set(MBEDTLS_ROOT ${CMAKE_BINARY_DIR}/vendor/mbedtls)
set(MBEDTLS_SRC ${CMAKE_BINARY_DIR}/vendor/mbedtls-src)
set(MBEDTLS_INCLUDE_DIRS ${MBEDTLS_ROOT}/include)
set(MBEDTLS_LIBRARIES ${MBEDTLS_ROOT}/lib/${CMAKE_FIND_LIBRARY_PREFIXES}mbedtls${CMAKE_STATIC_LIBRARY_SUFFIX} ${MBEDTLS_ROOT}/lib/${CMAKE_FIND_LIBRARY_PREFIXES}mbedx509${CMAKE_STATIC_LIBRARY_SUFFIX} ${MBEDTLS_ROOT}/lib/${CMAKE_FIND_LIBRARY_PREFIXES}mbedcrypto${CMAKE_STATIC_LIBRARY_SUFFIX})
ExternalProject_Add(
  mbedtls
  BUILD_BYPRODUCTS ${MBEDTLS_LIBRARIES}
  ARGS
    URL ${CMAKE_SOURCE_DIR}/vendor/mbedtls-2.16.4-apache.tgz
    SOURCE_DIR ${MBEDTLS_SRC}
    BINARY_DIR ${MBEDTLS_SRC}
    CONFIGURE_COMMAND echo "Building mbedTLS with make lib"
    BUILD_COMMAND make lib
    INSTALL_COMMAND make DESTDIR=${MBEDTLS_ROOT} install
)

set(CURL_ROOT ${CMAKE_BINARY_DIR}/vendor/curl)
set(CURL_SRC ${CMAKE_BINARY_DIR}/vendor/curl-src)
set(CURL_INCLUDE_DIRS ${CURL_ROOT}/include)
set(CURL_LIBRARIES ${CURL_ROOT}/lib/${CMAKE_FIND_LIBRARY_PREFIXES}curl${CMAKE_STATIC_LIBRARY_SUFFIX})
ExternalProject_Add(
  curl
  BUILD_BYPRODUCTS ${CURL_LIBRARIES}
  ARGS
    URL ${CMAKE_SOURCE_DIR}/vendor/curl-7.67.0.tar.gz
    SOURCE_DIR ${CURL_SRC}
    BINARY_DIR ${CURL_SRC}
    # Disable everything we can except mbed with extreme prejudice
    # --disable-ldap and --disable-ldaps should take care of -lldap and -llber
    # which were causing problems on my OS X machine
    # RTSP remains enabled in the minimal build container,
    # so we leave out --disable-rtsp 
    CONFIGURE_COMMAND ./configure --prefix=${CURL_ROOT} --with-mbedtls=${MBEDTLS_ROOT} --without-zlib --without-brotli --without-winssl --without-schannel --without-darwinssl --without-secure-transport --without-amissl --without-ssl --without-gnutls --without-wolfssl --without-mesalink --without-nss --without-libpsl --without-libmetalink --without-librtmp --without-winidn --without-libidn2 --without-nghttp2 --without-ngtcp2 --without-nghttp3 --without-quiche --without-zsh-functions-dir --without-fish-functions-dir --disable-ldap --disable-ldaps
    BUILD_COMMAND make
    INSTALL_COMMAND make install
    DEPENDS mbedtls
)

ExternalProject_Add(
  samtools-lib
  BUILD_BYPRODUCTS ${SAMTOOLS_LIB} ${HTSLIB_LIB}
  ARGS
    URL ${CMAKE_SOURCE_DIR}/vendor/samtools-1.10.tar.bz2
    SOURCE_DIR ${SAMTOOLS_ROOT}
    BINARY_DIR ${SAMTOOLS_ROOT}
    #CONFIGURE_COMMAND C_INCLUDE_PATH=${ZLIB_INCLUDE_DIRS}:${BZIP2_INCLUDE_DIRS} ./configure --without-curses
    #CONFIGURE_COMMAND ./configure --without-curses
    #PATCH_COMMAND patch -p2 -t -N < ${CMAKE_SOURCE_DIR}/vendor/Makefile.disable_curl.patch
    CONFIGURE_COMMAND echo "Building samtools, build log at ${SAMTOOLS_LOG}"
    BUILD_COMMAND make libbam.a > ${SAMTOOLS_LOG} 2>&1 &&
                  cd htslib-${SAMTOOLS_VERSION} &&
                  C_INCLUDE_PATH=${ZLIB_INCLUDE_DIRS}:${BZIP2_INCLUDE_DIRS}:${XZ_INCLUDE_DIRS}:${CURL_INCLUDE_DIRS} make libhts.a > ${HTSLIB_LOG} 2>&1
    INSTALL_COMMAND true
    DEPENDS zlib bzip2 xz curl
)


set(Samtools_INCLUDE_DIRS ${SAMTOOLS_ROOT})
set(Samtools_LIBRARIES ${SAMTOOLS_LIB})

set(Htslib_INCLUDE_DIRS ${HTSLIB_ROOT})
set(Htslib_LIBRARIES ${HTSLIB_LIB})

set(Support_INCLUDE_DIRS ${ZLIB_INCLUDE_DIRS} ${BZIP2_INCLUDE_DIRS} ${XZ_INCLUDE_DIRS} ${CURL_INCLUDE_DIRS} ${MBEDTLS_INCLUDE_DIRS})
set(Support_LIBRARIES pthread ${ZLIB_LIBRARIES} ${BZIP2_LIBRARIES} ${XZ_LIBRARIES} ${CURL_LIBRARIES} ${MBEDTLS_LIBRARIES})
