# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="bcm2835-driver"
PKG_VERSION="62fc8c01165a80021054a430182b504f7b877c2d"
PKG_SHA256="00cd04ae1c5b73de10e1a189b2b643fa349f08f06324d966227f147e72243bd9"
PKG_LICENSE="nonfree"
PKG_SITE="http://www.broadcom.com"
PKG_URL="${DISTRO_SRC}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain dtc"
PKG_LONGDESC="OpenMAX-bcm2835: OpenGL-ES and OpenMAX driver for BCM2835"
PKG_TOOLCHAIN="manual"

# Set SoftFP ABI or HardFP ABI
if [ "${TARGET_FLOAT}" = "soft" ]; then
  PKG_FLOAT="softfp"
else
  PKG_FLOAT="hardfp"
fi

post_unpack() {
  # do not build GLES stuff when not using as GLES driver
  if [ "${OPENGLES}" != "bcm2835-driver" -a "${OPENGL}" != "bcm2835-driver" ]; then
    rm -v $PKG_BUILD/$PKG_FLOAT/opt/vc/lib/pkgconfig/brcmegl.pc
    rm -v $PKG_BUILD/$PKG_FLOAT/opt/vc/lib/pkgconfig/brcmglesv2.pc

    rm -v $PKG_BUILD/$PKG_FLOAT/opt/vc/lib/libbrcmEGL.so
    rm -v $PKG_BUILD/$PKG_FLOAT/opt/vc/lib/libbrcmGLESv2.so
    rm -v $PKG_BUILD/$PKG_FLOAT/opt/vc/lib/libEGL.so
    rm -v $PKG_BUILD/$PKG_FLOAT/opt/vc/lib/libGLESv1_CM.so
    rm -v $PKG_BUILD/$PKG_FLOAT/opt/vc/lib/libGLESv2.so

    rm -v $PKG_BUILD/$PKG_FLOAT/opt/vc/lib/libEGL_static.a
    rm -v $PKG_BUILD/$PKG_FLOAT/opt/vc/lib/libGLESv2_static.a

    rm -vrf $PKG_BUILD/$PKG_FLOAT/opt/vc/include/EGL
    rm -vrf $PKG_BUILD/$PKG_FLOAT/opt/vc/include/GLES
    rm -vrf $PKG_BUILD/$PKG_FLOAT/opt/vc/include/GLES2
  fi
}

makeinstall_target() {
  # Install vendor header files
  mkdir -p ${SYSROOT_PREFIX}/usr/include
    if [ "${OPENGLES}" = "bcm2835-driver" ]; then
      cp -PRv ${PKG_FLOAT}/opt/vc/include/* ${SYSROOT_PREFIX}/usr/include
    else
      for f in $(cd ${PKG_FLOAT}/opt/vc/include; ls | grep -v "GL"); do
        cp -PRv ${PKG_FLOAT}/opt/vc/include/$f ${SYSROOT_PREFIX}/usr/include
      done
    fi

  # Install EGL, OpenGL ES, Open VG, etc. vendor libs & pkgconfigs
  mkdir -p ${SYSROOT_PREFIX}/usr/lib
    if [ "${OPENGLES}" = "bcm2835-driver" ]; then
      cp -PRv ${PKG_FLOAT}/opt/vc/lib/*.so              ${SYSROOT_PREFIX}/usr/lib
      ln -sf ${SYSROOT_PREFIX}/usr/lib/libbrcmEGL.so    ${SYSROOT_PREFIX}/usr/lib/libEGL.so
      ln -sf ${SYSROOT_PREFIX}/usr/lib/libbrcmGLESv2.so ${SYSROOT_PREFIX}/usr/lib/libGLESv2.so
      cp -PRv ${PKG_FLOAT}/opt/vc/lib/*.a               ${SYSROOT_PREFIX}/usr/lib
      cp -PRv ${PKG_FLOAT}/opt/vc/lib/pkgconfig         ${SYSROOT_PREFIX}/usr/lib
    else
      for f in $(cd ${PKG_FLOAT}/opt/vc/lib; ls *.so *.a | grep -Ev "^lib(EGL|GL)"); do
        cp -PRv ${PKG_FLOAT}/opt/vc/lib/$f              ${SYSROOT_PREFIX}/usr/lib
      done
      mkdir -p ${SYSROOT_PREFIX}/usr/lib/pkgconfig
        for f in $(cd ${PKG_FLOAT}/opt/vc/lib/pkgconfig; ls | grep -v "gl"); do
          cp -PRv ${PKG_FLOAT}/opt/vc/lib/pkgconfig/$f  ${SYSROOT_PREFIX}/usr/lib/pkgconfig
        done
    fi

  # Update prefix in vendor pkgconfig files
  for PKG_CONFIGS in $(find "${SYSROOT_PREFIX}/usr/lib" -type f -name "*.pc" 2>/dev/null); do
    sed -e "s#prefix=/opt/vc#prefix=/usr#g" -i "${PKG_CONFIGS}"
  done

  # Create symlinks to /opt/vc to satisfy hardcoded include & lib paths
  mkdir -p ${SYSROOT_PREFIX}/opt/vc
    ln -sf ${SYSROOT_PREFIX}/usr/lib     ${SYSROOT_PREFIX}/opt/vc/lib
    ln -sf ${SYSROOT_PREFIX}/usr/include ${SYSROOT_PREFIX}/opt/vc/include

  # Install EGL, OpenGL ES and other vendor libs
  mkdir -p ${INSTALL}/usr/lib
    if [ "${OPENGLES}" = "bcm2835-driver" ]; then
      cp -PRv ${PKG_FLOAT}/opt/vc/lib/*.so ${INSTALL}/usr/lib
      ln -sf /usr/lib/libbrcmEGL.so        ${INSTALL}/usr/lib/libEGL.so
      ln -sf /usr/lib/libbrcmEGL.so        ${INSTALL}/usr/lib/libEGL.so.1
      ln -sf /usr/lib/libbrcmGLESv2.so     ${INSTALL}/usr/lib/libGLESv2.so
      ln -sf /usr/lib/libbrcmGLESv2.so     ${INSTALL}/usr/lib/libGLESv2.so.2
    else
      for f in $(cd ${PKG_FLOAT}/opt/vc/lib; ls *.so | grep -Ev "^lib(EGL|GL)"); do
        cp -PRv ${PKG_FLOAT}/opt/vc/lib/$f ${INSTALL}/usr/lib
      done
    fi

  # Install useful tools
  mkdir -p ${INSTALL}/usr/bin
    cp -PRv ${PKG_FLOAT}/opt/vc/bin/dtoverlay  ${INSTALL}/usr/bin
    ln -s dtoverlay                            ${INSTALL}/usr/bin/dtparam
    cp -PRv ${PKG_FLOAT}/opt/vc/bin/vcdbg      ${INSTALL}/usr/bin
    cp -PRv ${PKG_FLOAT}/opt/vc/bin/vcgencmd   ${INSTALL}/usr/bin
    cp -PRv ${PKG_FLOAT}/opt/vc/bin/vcmailbox  ${INSTALL}/usr/bin
    cp -PRv ${PKG_FLOAT}/opt/vc/bin/tvservice  ${INSTALL}/usr/bin
    cp -PRv ${PKG_FLOAT}/opt/vc/bin/edidparser ${INSTALL}/usr/bin

  # Create symlinks to /opt/vc to satisfy hardcoded lib paths
  mkdir -p ${INSTALL}/opt/vc
    ln -sf /usr/bin ${INSTALL}/opt/vc/bin
    ln -sf /usr/lib ${INSTALL}/opt/vc/lib
}

post_install() {
  # unbind Framebuffer console
  if [ "${OPENGLES}" = "bcm2835-driver" ]; then
    enable_service unbind-console.service
  fi
}
