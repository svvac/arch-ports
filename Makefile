PKG := $(filter %/,$(wildcard ./*/*/))
AUR_BRANCH=master

%/.aur: %/.SRCINFO
	touch "$@"

%/.aur-push: %/.aur
	git subtree push --prefix "$(@D)" "ssh://aur@aur.archlinux.org/$(notdir $(@D)).git" $(AUR_BRANCH)
	git subtree pull --squash --prefix "$(@D)" "ssh://aur@aur.archlinux.org/$(notdir $(@D)).git" $(AUR_BRANCH)

%/.checksum: %/PKGBUILD
	updpkgsums "$(@D)/PKGBUILD"
	touch "$@"

%/PKGBUILD:

%/.SRCINFO: %/PKGBUILD %/.checksum
	cd $(@D); makepkg --printsrcinfo > .SRCINFO

srcinfo: $(addsuffix .SRCINFO, $(PKG))
checksum: $(addsuffix .checksum, $(PKG))
aur: $(addsuffix .aur, $(PKG))
aur-push: $(addsuffix .aur-push, $(PKG))

.PRECIOUS: %/PKGBUILD
.PHONY: aur srcinfo checksum aur-push
