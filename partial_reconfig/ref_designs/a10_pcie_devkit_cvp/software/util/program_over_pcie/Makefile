CXX = /usr/bin/g++ -o 
CPPFLAGS = -Wall -Wno-unknown-pragmas -D__USE_XOPEN2K8 -Werror -I. -I../../driver
CXXFLAGS = -fPIC -m64

LINKER = /usr/bin/g++
LINKER_ARGS = -fPIC -Wl,--no-undefined

EXEFILE = program_over_pcie

OBJ_FILES = \
	lib.o \
	main.o

$(EXEFILE) : $(OBJ_FILES)
	$(LINKER) $(CXXFLAGS) -o $@ $(OBJ_FILES) $(LINKER_ARGS)

%.o : %.cpp
	$(ECHO)$(CXX)$@ -c $(CPPFLAGS) $(CXXFLAGS) $<

.DEFAULT_GOAL = all
all : $(EXEFILE)

.PHONY : clean
clean :
	rm -rf $(OBJ_FILES) $(EXEFILE)