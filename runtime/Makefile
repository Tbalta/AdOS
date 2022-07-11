RUNTIME_BINARY := ${LIB_DIR}/libgnat.a
RUNTIME_PROJ   := runtime
 
SRC_DIR        := src
BUILD_DIR      := build
LIB_DIR        := ${BUILD_DIR}/adalib
INCLUDE_DIR    := ${BUILD_DIR}/adainclude
 
LINKER_SCRIPT  := x86-multiboot.ld
RUNTIME_CONFIG := runtime.xml
 
.PHONY: clean
 
all: ${RUNTIME_BINARY}
 
clean:
	gprclean -P${RUNTIME_PROJ}
	rm -rf ${BUILD_DIR}
 
# Build the run-time library.
${RUNTIME_BINARY}: ${INCLUDE_DIR}/*.ad[sb] ${INCLUDE_DIR}/*.S \
	${LIB_DIR} ${BUILD_DIR}/${LINKER_SCRIPT} ${BUILD_DIR}/${RUNTIME_CONFIG}
	gprbuild -P${RUNTIME_PROJ}
 
# Copy all Ada source files to the final include directory.
${INCLUDE_DIR}/*.ad[sb]: ${SRC_DIR}/*.ad[sb] ${COMMON_SRC_DIR}/*.ad[sb] ${INCLUDE_DIR}
	cp -a ${SRC_DIR}/*.ad[sb] ${INCLUDE_DIR}
 
# Copy any Assemblersource files to the final include directory.
${INCLUDE_DIR}/*.S: ${SRC_DIR}/*.S ${INCLUDE_DIR}
	cp -a ${SRC_DIR}/*.S ${INCLUDE_DIR}
 
# Copy the linker script to the final run-time directory.
${BUILD_DIR}/${LINKER_SCRIPT}:
	cp -a ${SRC_DIR}/${LINKER_SCRIPT} ${BUILD_DIR}/${LINKER_SCRIPT}
 
# Copy our run-time config to the final run-time directory.
${BUILD_DIR}/${RUNTIME_CONFIG}:
	cp -a ${SRC_DIR}/${RUNTIME_CONFIG} ${BUILD_DIR}/${RUNTIME_CONFIG}
 
# Create the necesary directory tree.
${INCLUDE_DIR}:
	mkdir -p ${INCLUDE_DIR}
 
${LIB_DIR}:
	mkdir -p ${LIB_DIR}
