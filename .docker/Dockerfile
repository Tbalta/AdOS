FROM ubuntu:24.04

RUN apt update && apt upgrade -y

# GCC dependency
RUN apt -y install build-essential gnat-13 gprbuild nasm build-essential wget  make
RUN apt -y install bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo

# Create /src to clone binutils
RUN mkdir /src
WORKDIR /src

# Clone binutils
RUN wget https://sourceware.org/pub/binutils/releases/binutils-2.40.tar.gz && \
    tar -xzf binutils-2.40.tar.gz && \
    rm binutils-2.40.tar.gz

# Clone GCC
RUN wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.gz && \
    tar -xzf gcc-13.2.0.tar.gz && \
    rm gcc-13.2.0.tar.gz

# Copy gnat_crosscompile.sh script
COPY gnat_crosscompile.sh /src/gnat_crosscompile.sh
RUN chmod +x /src/gnat_crosscompile.sh

COPY .bashrc /root/.bashrc


RUN /src/gnat_crosscompile.sh
ENV PATH="$PATH:/opt/cross/i386-elf/bin"

RUN ln -s /opt/cross/i386-elf/bin/i386-elf-gcc /opt/cross/i386-elf/bin/i386-elf-gnatgcc
COPY linker.xml /usr/share/gprconfig/linker.xml
COPY compilers.xml /usr/share/gprconfig/compilers.xml

RUN apt -y install grub-common xorriso grub-pc wget unzip git curl

RUN wget https://github.com/alire-project/alire/releases/download/v2.1.0/alr-2.1.0-bin-x86_64-linux.zip
RUN unzip alr-2.1.0-bin-x86_64-linux.zip
RUN cp bin/alr /usr/local/bin