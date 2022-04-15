
# linux / gcc options
CC=gcc
EXE = 
LDFLAGS = -ldl
FC=gfortran


# Windows / gcc options
# CC=gcc
# EXE = .exe
# LDFLAGS = 


# CFLAGS=-I. -g
CFLAGS = -I. -O2 -Wall
DEPS = julia_embedding.h PALEO_cfunctions.h
COBJ = julia_embedding.o PALEO_cfunctions.o test_PALEO_C.o
# FFLAGS= -g
FFLAGS = -O2 -Wall
FDEPS = paleo_fortran.mod
FOBJ =  julia_embedding.o PALEO_cfunctions.o PALEO_fortran.o test_PALEO_F.o

#=============================================================================

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

%.o: %.f90 
	$(FC) -c -o $@ $< $(FFLAGS)

all: test_PALEO_C$(EXE) test_PALEO_F$(EXE)

test_PALEO_C$(EXE): $(COBJ)
	$(CC) -o $@ $^ $(CFLAGS) $(LDFLAGS)

test_PALEO_F$(EXE): $(FOBJ)
	$(FC) -o $@ $^ $(FFLAGS) $(LDFLAGS)

clean:
	rm -f *.o *.mod test_PALEO_C$(EXE) test_PALEO_F$(EXE)

.PHONY: clean
