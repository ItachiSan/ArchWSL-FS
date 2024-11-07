FROM archlinux:latest
# Ensure we have base-devel
RUN pacman -Syu --needed --noconfirm base-devel
# Add regular user for makepkg
RUN useradd -m build
RUN echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# Set up the entrypoint
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
