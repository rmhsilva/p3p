# Hello make
# Ricardo da Silva, 2013

# Final ELF name
TARGET = main

# Source files
# Automatically create header dependencies from the source files
SOURCES = main.c serial.c preProcess.c sample.c gpio.c libmfcc/libmfcc.c
DEPS = $(SOURCES:%.c=%.h)

# Directory for all the objects (must not be blank!)
# Automatically create the objects too!
# The directories *must* be created first....
OBJDIR = ./obj
OBJECTS = $(SOURCES:%.c=$(OBJDIR)/%.o)

# Optimisation level (0->3 == slow->fast program. s == small program)
OPT = 2

# Libraries needed
LIBS = -lm -lfftw3

# Where to look for more libraries and includes
LIBDIRS = /home/ltib/ltib/rootfs/usr/lib
INCDIRS = /home/ltib/ltib/rootfs/usr/include


# Set up the C compiler flags
CFLAGS = -I. $(patsubst %,-I%,$(INCDIRS))
CFLAGS += -O$(OPT)
CFLAGS += -Wall

# And linker flags
LDFLAGS = $(patsubst %,-L%,$(LIBDIRS))
LDFLAGS += $(LIBS)


# Use the cross compiler GCC
CC = /opt/freescale/usr/local/gcc-4.1.2-glibc-2.5-nptl-3/arm-none-linux-gnueabi/arm-none-linux-gnueabi/bin/gcc
RM = rm -f


# Default (first) target
all: begin $(TARGET) end

# Start and finish messages
begin:
	@echo
	@echo --- Starting ---
end:
	@echo
	@echo --- Done ---


# Compile target
$(TARGET): $(OBJECTS)
	@echo
	@echo + Creating Target
	$(CC) -o $@ $^ $(CFLAGS) $(LDFLAGS)

# Compile object files
$(OBJDIR)/%.o : %.c $(DEPS)
	@echo
	@echo + Creating Object file from $<
	$(CC) -o $@ -c $< $(CFLAGS)


clean: begin clean_all end

clean_all:
	@echo
	@echo + Cleaning up
	$(RM) $(OBJECTS)
	$(RM) $(TARGET)

# List of targets that.. aren't really targets.
.PHONY : all begin end build clean clean_all
