FROM ubuntu AS build-gcc

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    dos2unix file g++ make patch texinfo unzip wget \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

COPY *.patch /usr/src

ARG BINUTILS_VERSION=2.36.1
ARG GCC_VERSION=9.3.0
ARG NEWLIB_VERSION=4.1.0

ARG SGDK_VERSION=1.62

RUN wget https://ftp.gnu.org/pub/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz \
  && tar xfz binutils-${BINUTILS_VERSION}.tar.gz \
  && cd binutils-${BINUTILS_VERSION} \
  && mkdir build \
  && cd build \
  && ../configure \
    --prefix=/opt/sgdk \
    --target=m68k-elf \
    --enable-install-libbfd \
    --disable-nls \
    --disable-werror \
  && make -j4 \
  && make install-strip

RUN wget https://ftp.gnu.org/pub/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz \
  && tar xfz gcc-${GCC_VERSION}.tar.gz \
  && cd gcc-${GCC_VERSION} \
  && ./contrib/download_prerequisites \
  && mkdir build-stage1 \
  && cd build-stage1 \
  && ../configure \
    --prefix=/opt/sgdk \
    --target=m68k-elf \
    --with-cpu=m68000 \
    --with-newlib \
    --without-headers \
    --enable-languages=c \
    --disable-libssp \
    --disable-multilib \
    --disable-nls \
    --disable-tls \
    --disable-werror \
  && make -j4 \
  && make install-strip

RUN wget https://sourceware.org/pub/newlib/newlib-${NEWLIB_VERSION}.tar.gz \
  && tar xfz newlib-${NEWLIB_VERSION}.tar.gz \
  && cd newlib-${NEWLIB_VERSION} \
  && mkdir build \
  && cd build \
  && PATH=/opt/sgdk/bin:$PATH ../configure \
    --prefix=/opt/sgdk \
    --target=m68k-elf \
    --with-cpu=m68000 \
    --disable-werror \
  && PATH=/opt/sgdk/bin:$PATH make -j4 \
  && PATH=/opt/sgdk/bin:$PATH make install

RUN cd gcc-${GCC_VERSION} \
  && mkdir build-stage2 \
  && cd build-stage2 \
  && ../configure \
    --prefix=/opt/sgdk \
    --target=m68k-elf \
    --with-cpu=m68000 \
    --with-newlib \
    --enable-threads=single \
    --enable-languages=c \
    --disable-libssp \
    --disable-multilib \
    --disable-nls \
    --disable-tls \
    --disable-werror \
  && make -j4 \
  && make install-strip

RUN wget https://github.com/kubilus1/gendev/raw/master/tools/files/sjasm39g6.zip \
  && unzip sjasm39g6.zip -d sjasm \
  && cd sjasm/sjasmsrc39g6 \
  && make \
  && cp sjasm /opt/sgdk/bin

RUN wget https://github.com/Stephane-D/SGDK/archive/v${SGDK_VERSION}.tar.gz -O sgdk-${SGDK_VERSION}.tar.gz \
  && tar xfz sgdk-${SGDK_VERSION}.tar.gz \
  && mv SGDK-${SGDK_VERSION} SGDK \
  && patch -p0 < sgdk.patch \
  && cd SGDK \
  && find . -type f \( -name \*.c -o -name \*.h -o -name \*.i -o -name \*.ld -o -name \*.res -o -name \*.s -o -name \*.i80 -o -name \*.s80 \) -exec dos2unix {} \;

RUN cd SGDK/tools/bintos/src \
  && gcc -s -O2 -Wall -o bintos bintos.c \
  && cp bintos /opt/sgdk/bin

RUN cd SGDK/tools/sizebnd/src \
  && gcc -s -O2 -Wall -o sizebnd sizebnd.c \
  && cp sizebnd /opt/sgdk/bin

RUN cd SGDK/tools/xgmtool/src \
  && gcc -s -O2 -Wall -o xgmtool *.c -I../inc -lm \
  && cp xgmtool /opt/sgdk/bin

FROM ghcr.io/graalvm/graalvm-ce AS build-graalvm

RUN gu install native-image

WORKDIR /usr/src

COPY --from=build-gcc /usr/src/SGDK /usr/src/SGDK

COPY *.json /usr/src/configs/

RUN cd SGDK/bin \
  && native-image --no-fallback --static -jar apj.jar \
  && native-image --no-fallback --static -jar lz4w.jar \
  && native-image --no-fallback --static -H:ConfigurationFileDirectories=/usr/src/configs -jar rescomp.jar

FROM ubuntu AS build-upx

RUN apt-get update \
  && apt-get install -y upx \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

COPY --from=build-graalvm /usr/src/SGDK /usr/src/SGDK

RUN cd SGDK/bin \
  && upx -9 apj \
  && upx -9 lz4w \
  && upx -9 rescomp \
  && mkdir -p /opt/sgdk/bin \
  && cp apj lz4w rescomp /opt/sgdk/bin

FROM ubuntu AS build-sgdk

RUN apt-get update \
  && apt-get install -y make \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build-gcc /opt/sgdk /opt/sgdk
COPY --from=build-upx /opt/sgdk /opt/sgdk
ENV PATH /opt/sgdk/bin:$PATH

WORKDIR /usr/src

COPY --from=build-graalvm /usr/src/SGDK /usr/src/SGDK

RUN cd SGDK \
  && make -f makelib.gen cleanrelease \
  && make -f makelib.gen release \
  && make -f makelib.gen cleandebug \
  && make -f makelib.gen debug \
  && rm lib/libgcc.a res/libres.d \
  && cp -r inc lib res md.ld /opt/sgdk

FROM ubuntu

RUN apt-get update \
  && apt-get install -y make \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build-sgdk /opt/sgdk /opt/sgdk
ENV PATH /opt/sgdk/bin:$PATH
WORKDIR /workdir
