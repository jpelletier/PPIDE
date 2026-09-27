#.PHONY: all clean verify

PROJECT = PPIDE
LIB_NAME = $(PROJECT).LIB
USE_F8087 = -f87

TCPP_DIR = P:\DOS\APPS\PROG\C_CPP\TCPP
TASM_DIR = P:\DOS\APPS\PROG\ASM\TASM

CC = $(TCPP_DIR)\BIN\TCC
LIB = $(TCPP_DIR)\BIN\TLIB
ASM = $(TASM_DIR)\TASM

OPTIONS = -ms -w -I$(TCPP_DIR)\INCLUDE
#-I$(TASM_DIR)\INCLUDE
LK_OPTIONS = -ms -L$(TCPP_DIR)\LIB
AS_OPTIONS = /l /m2
#/m $(PROJECT).MAP

# Find all .cpp source files
SRCS = $(wildcard *.cpp)
# Define object files based on .cpp files
#OBJS = $(SRCS:.cpp=.obj)
OBJS = PPIDE.obj

# Default target: Build the library
all: $(LIB_NAME)

# Rule to compile C files to Object files
.cpp.obj:
	$(CC) $(OPTIONS) -c $<

# Rule to compile ASM files to Object files
.asm.obj:
	$(ASM) $(AS_OPTIONS) -c $<

# Rule to bundle Object files into the Library
$(LIB_NAME): $(OBJS)
	$(LIB) $(PROJECT) @list.txt

# Target to verify library symbols
#verify: $(LIB_NAME)
#	$(NM) $(LIB_NAME)

install:
	copy $(LIB_NAME) ..\LIB
	copy PPIDE.h ..\INC

# Target to clean up generated files
clean:
	del *.obj
	del *.LIB
	del *.LST
