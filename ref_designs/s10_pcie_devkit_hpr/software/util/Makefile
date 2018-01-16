CPPFLAGS = -Wall -Werror -Wformat-security \
	-Wno-unknown-pragmas -D__USE_XOPEN2K8 -fstack-protector -I. \
	-O2 -D_FORTIFY_SOURCE=2

LINKER = /usr/bin/gcc -lrt

EXEFILE = example_host_uio

OBJ_FILES = \
	example_host_uio.o

$(EXEFILE) : $(OBJ_FILES)
	$(LINKER) -o $@ $(OBJ_FILES)

%.o : %.cpp
	$(ECHO)$(CC)$@ -c $(CPPFLAGS) $<

.DEFAULT_GOAL = all
all : $(EXEFILE)

.PHONY : clean
clean :
	rm -rf $(OBJ_FILES) $(EXEFILE)
