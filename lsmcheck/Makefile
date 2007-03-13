CC=gcc
CFLAGS=-Wall -O -I/usr/local/include
LDFLAGS=
LIBS=-L/usr/local/lib -lpub -lncurses

bindir=/usr/local/bin

progs = lsmcheck lsmextract lsmfmt lsmadd

all: $(progs)

link:
	rm -f $(progs) && $(MAKE) all

lsmadd: lsmadd.o 
	$(CC) $(LDFLAGS) -o lsmadd lsmadd.o $(LIBS)

lsmcheck: lsmcheck.o 
	$(CC) $(LDFLAGS) -o lsmcheck lsmcheck.o $(LIBS)

lsmextract: lsmextract.o 
	$(CC) $(LDFLAGS) -o lsmextract lsmextract.o $(LIBS)

lsmfmt: lsmfmt.o 
	$(CC) $(LDFLAGS) -o lsmfmt lsmfmt.o $(LIBS)

install:
	install $(progs) $(bindir)

clean:
	rm -f $(progs) *.o core
