rootdir := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
AUR_BRANCH=master
REPODIR=_repository
REPONAME=robotengin
MAKEPKG_OPTS=PACKAGER="svvac <_@svvac.net>"
CHROOTDIR=_chroot
chrootdir=$(rootdir)/$(CHROOTDIR)
repodir=$(rootdir)/$(REPODIR)
PKG := $(filter %/,$(filter-out $(rootdir)/_%, $(wildcard $(rootdir)/*/*/)))


$(CHROOTDIR):
	mkdir -p "$@"
	mkarchroot "$@" base-devel

$(CHROOTDIR)/root.update: $(CHROOTDIR) $(REPODIR)
	arch-nspawn "$(CHROOTDIR)/root" --bind="$(repodir):/repo" pacman -Syu
	touch "$@"



$(REPODIR):
	mkdir -p "$@"

%/.aur: %/.SRCINFO
	touch "$@"

%/.aur-push: %/.aur
	git subtree push --prefix "$(@D)" "ssh://aur@aur.archlinux.org/$(notdir $(@D)).git" $(AUR_BRANCH)
	git subtree pull --squash --prefix "$(@D)" "ssh://aur@aur.archlinux.org/$(notdir $(@D)).git" $(AUR_BRANCH)

%/.checksum: %/PKGBUILD
	updpkgsums "$(@D)/PKGBUILD"
	touch "$@"

%/.build: %/PKGBUILD
	cd "$(@D)" ; makechrootpkg -c -r "$(chrootdir)" -d "$(repodir):/repo" -- -srfCc --nosign PKGDEST="/repo" $(MAKEPKG_OPTS)
	rm -f "$(@D)/"*.pkg.tar.xz "$(@D)/"*.pkg.tar.xz.sig
	gpg --detach-sign "$(wildcard $(repodir)/$(notdir $(@D))-*.pkg.tar.xz)"
	ln -s "$(repodir)/$(notdir $(wildcard $(repodir)/$(notdir $(@D))-*.pkg.tar.xz))" "$(@D)"
	ln -s "$(repodir)/$(notdir $(wildcard $(repodir)/$(notdir $(@D))-*.pkg.tar.xz)).sig" "$(@D)"
	echo "$(notdir $(wildcard $(repodir)/$(notdir $(@D))-*.pkg.tar.xz))" > "$@"

%/PKGBUILD:

%/.SRCINFO: %/PKGBUILD %/.checksum
	cd $(@D); makepkg --printsrcinfo > .SRCINFO

srcinfo: $(addsuffix .SRCINFO, $(PKG))
checksum: $(addsuffix .checksum, $(PKG))
aur: $(addsuffix .aur, $(PKG))
aur-push: $(addsuffix .aur-push, $(PKG))
repository: $(REPODIR) $(CHROOTDIR)/root.update $(addsuffix .build, $(PKG))
	repo-add --new --sign -R "$(REPODIR)/$(REPONAME).db.tar.gz" "$(REPODIR)/"*.pkg.tar.xz
clean:
	git clean -xdfe '/_*' -- .
chroot: $(CHROOTDIR)/root
chroot-update: $(CHROOTDIR)/root.update

.PRECIOUS: %/PKGBUILD
.NOTPARALLEL: *.aur-push
.PHONY: aur srcinfo checksum aur-push clean chroot chroot-update
