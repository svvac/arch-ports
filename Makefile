rootdir := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))/
PKG := $(filter %/,$(wildcard $(rootdir)*/*/))
AUR_BRANCH=master
REPODIR=_repository


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
	cd "$(@D)" ; PKGDEST="$(rootdir)$(REPODIR)" makepkg -srfCc
	touch "$@"

%/PKGBUILD:

%/.SRCINFO: %/PKGBUILD %/.checksum
	cd $(@D); makepkg --printsrcinfo > .SRCINFO

srcinfo: $(addsuffix .SRCINFO, $(PKG))
checksum: $(addsuffix .checksum, $(PKG))
aur: $(addsuffix .aur, $(PKG))
aur-push: $(addsuffix .aur-push, $(PKG))
repository: $(REPODIR) $(addsuffix .build, $(PKG))
clean:
	git clean -xdfe '$(REPODIR)' -- .

.PRECIOUS: %/PKGBUILD
.NOTPARALLEL: *.aur-push
.PHONY: aur srcinfo checksum aur-push clean
