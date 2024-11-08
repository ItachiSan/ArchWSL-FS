# Target final output, the tarball ready for WSL2
OUT_TGZ           = rootfs.tar.gz
# Version for the tarball
ARCH_VERSION     ?= 2024.11.01
# Variables for fetching stuff
CURL              = curl -L
BOOTSTRAP_TAR_URL = https://mirrors.edge.kernel.org/archlinux/iso/$(ARCH_VERSION)/archlinux-bootstrap-x86_64.tar.zst
BASE_PACKAGES     = archlinux-keyring base less nano sudo vim curl
# Helper variables e.g. commands aliases
CHROOT            = sudo ./scripts/arch-chroot root.x86_64

# Main rule, for making our hard work
all: $(OUT_TGZ)

$(OUT_TGZ): .target/customized_rootfs
	@echo -e '\e[1;31mBuilding $(OUT_TGZ)\e[m'
	cd root.x86_64; sudo tar -cpf ../$(OUT_TGZ) *
	sudo chown `id -un` $(OUT_TGZ)

# Rules for making the chroot work environment
bootstrap_$(ARCH_VERSION).tar.zst:
	@echo -e '\e[1;31mDownloading $@...\e[m'
	$(CURL) $(BOOTSTRAP_TAR_URL) -o bootstrap_$(ARCH_VERSION).tar.zst

.target/base_rootfs: bootstrap_$(ARCH_VERSION).tar.zst
	@echo -e '\e[1;31mExtracting rootfs and prepare it for work...\e[m'
	sudo tar -xpf bootstrap_$(ARCH_VERSION).tar.zst root.x86_64
	sudo chmod +x root.x86_64
# Do these in regular chroot environment
#	sudo mount -t proc /proc root.x86_64/proc/
#	sudo mount -t sysfs /sys root.x86_64/sys/
#	sudo mount --rbind /dev  root.x86_64/dev/
#	sudo mount --rbind /run  root.x86_64/run/
	sudo mount --bind root.x86_64 root.x86_64
	mkdir -p .target
	touch $@

# Rule for building a package
%.pkg.tar.zst:
	@echo -e '\e[1;31mBuilding $*...\e[m'
	mkdir -p .build
	cd .build ; $(CURL) -O https://aur.archlinux.org/cgit/aur.git/snapshot/$*.tar.gz
	cd .build ; tar xf $*.tar.gz
	-cd .build/$* ; makepkg -src ; rm *debug*.pkg.tar.zst; cp -v $*-*.pkg.tar.zst ../../$*.pkg.tar.zst

# Rule for installing a package
.target/installed_%: %.pkg.tar.zst .target/base_rootfs
	@echo -e '\e[1;31mInstalling $*...\e[m'
	sudo cp $*.pkg.tar.zst root.x86_64/opt/$*.pkg.tar.zst
	yes | $(CHROOT) /usr/bin/pacman -U /opt/$*.pkg.tar.zst
	sudo rm root.x86_64/opt/$*.pkg.tar.zst
	mkdir -p .target
	touch $@

# Rules for building the correct rootfs
.target/initial_rootfs: .target/base_rootfs
	@echo -e '\e[1;31mAdding minimal mirrorlist...\e[m'
	sudo cp -vf files/mirrorlist root.x86_64/etc/pacman.d/mirrorlist

	@echo -e '\e[1;31mSet up locales...\e[m'
	sudo sed -i -e "s/#en_US.UTF-8/en_US.UTF-8/" root.x86_64/etc/locale.gen
	echo "LANG=en_US.UTF-8" | sudo tee root.x86_64/etc/locale.conf
	sudo ln -sf /etc/locale.conf root.x86_64/etc/default/locale
	$(CHROOT) locale-gen

# Re-enable if needed
#	@echo -e '\e[1;31mInstalling special hook for ping as regular user...\e[m'
#	sudo cp -f files/setcap-iputils.hook root.x86_64/usr/share/libalpm/hooks/50-setcap-iputils.hook

	@echo -e '\e[1;31mSet up Archlinux keyring...\e[m'
	$(CHROOT) pacman-key --init
	$(CHROOT) pacman-key --populate archlinux

	@echo -e '\e[1;31mInstalling basic packages...\e[m'
	$(CHROOT) pacman -Syu --noconfirm $(BASE_PACKAGES)

	mkdir -p .target
	touch $@

.target/customized_rootfs: .target/initial_rootfs .target/installed_fakeroot-tcp glibc-linux4.pkg.tar.zst
	@echo -e '\e[1;31mCleaning files from rootfs...\e[m'
	yes | $(CHROOT) pacman -Scc
	echo "# This file was automatically generated by WSL. To stop automatic generation of this file, remove this line." | sudo tee root.x86_64/etc/resolv.conf
	sudo rm -f root.x86_64/etc/machine-id
	sudo rm -f root.x86_64/usr/lib/systemd/system/sysinit.target.wants/systemd-firstboot.service

	@echo -e '\e[1;31mCopy extra files to rootfs...\e[m'
	sudo cp files/bash_profile root.x86_64/root/.bash_profile
	sudo cp glibc-linux4.pkg.tar.zst root.x86_64/root/glibc-linux4.pkg.tar.zst
	sudo cp files/wsl.conf root.x86_64/etc/wsl.conf
	touch $@

# Cleaning rules
clean: cleanroot cleanpkg
distclean: clean cleanbuild cleanbase

cleanmount:
	-sudo umount --recursive root.x86_64

cleanroot: cleanmount
	-sudo rm -rf root.x86_64
	-rm -f .target/customized_rootfs
	-rm -f .target/initial_rootfs
	-rm -f .target/base_rootfs

cleanpkg:
	-rm -f rootfs.tar.gz
	-rm -f .target/installed_fakeroot-tcp
	-rm -f fakeroot-tcp.pkg.tar.zst
	-rm -f glibc-linux4.pkg.tar.zst

cleanbase:
	-rm -f bootstrap_$(ARCH_VERSION).tar.zst

cleanbuild:
	-rm -rf .build
	-rm -rf .target
