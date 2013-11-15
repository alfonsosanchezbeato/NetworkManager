# Path for dependencies installed locally
#export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/

get_timestamp() {
    date --utc '+%Y%m%d-%H%M%S'
}
log_timestamp() {
    echo "STARTING_NEXT_PHASE: `get_timestamp`"
}
DATE="`get_timestamp`"
REPO=ssh://Jenkins-nm-user/var/lib/git/NetworkManager.git

git_notes() {
    git fetch "$REPO" +refs/notes/test:refs/notes/test || git update-ref -d refs/notes/test

    # git-notes append adds a newline so merge them by hand...
    NOTE="$(git notes --ref=test show HEAD 2>/dev/null || true)"
    if [[ "x$NOTE" != "x" ]]; then
        newline='
'
        if [[ "${NOTE#"${NOTE%?}"}" != "$newline" ]]; then
            NOTE="$NOTE$newline"
        fi
    fi

    git notes --ref test add -f -m "$NOTE$1" HEAD
    git push "$REPO" refs/notes/test:refs/notes/test
}

git_notes_ok() {
    git_notes "Tested: OK   $DATE $BUILD_URL"
}
git_notes_fail() {
    git_notes "Tested: FAIL $DATE $BUILD_URL"
}

trap "git_notes_fail; exit 1" ERR



temporary_workaround_01() {
    # https://bugzilla.gnome.org/show_bug.cgi?id=705160
    # otherwise current mem leaks check fail...
    wget 'https://bugzilla.gnome.org/attachment.cgi?id=256245' -O valgrind.suppressions.patch
    git apply valgrind.suppressions.patch
}

log_timestamp
git reset --hard HEAD
git clean -fdx
git submodule foreach git clean -fdx
git submodule update

temporary_workaround_01


#export CFLAGS="-Wall -g -O0 -fstack-protector-strong -Wno-deprecated-declarations"
# yum install ppp-devel polkit-devel vala-compat-tools gcc-c++


log_timestamp
./autogen.sh --enable-maintainer-mode --prefix=$PWD/.INSTALL/ --with-dhclient=yes --with-dhcpcd=yes --with-crypto=nss --enable-more-warnings=error --enable-ppp=yes --enable-polkit=yes --with-session-tracking=systemd --with-suspend-resume=systemd --with-tests=yes --enable-tests=yes --with-valgrind=yes --enable-ifcfg-rh=yes --enable-ifupdown=yes --enable-ifnet=yes --enable-gtk-doc --enable-qt=yes --with-system-libndp=no --enable-static=libndp --enable-bluez4=no --enable-wimax=no --enable-vala=no --enable-modify-system=no


log_timestamp
make


log_timestamp
make check


log_timestamp
make distcheck


log_timestamp
wget http://file.brq.redhat.com/~thaller/nmtui-0.0.1.tar.xz
git checkout origin/th/automation -- :/contrib/
./contrib/rpm/build.sh


log_timestamp
git_notes_ok

