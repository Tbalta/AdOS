
BIN_DIR = bin

PROJECTS = libc test snake

PROJECTS_CLEAN = $(PROJECTS:%=%.clean)

.PHONY: make_dir $(PROJECTS) $(PROJECTS_CLEAN) clean

all: make_dir $(PROJECTS)

make_dir:
	mkdir -p $(BIN_DIR)

$(PROJECTS):
	$(MAKE) -C $@


$(PROJECTS_CLEAN):
	$(MAKE) -C $(@:.clean=) clean

clean: $(PROJECTS_CLEAN)
	echo $(PROJECTS_CLEAN)
	$(RM) -r $(BIN_DIR)