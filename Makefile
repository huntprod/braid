all: msgtest randcat
test:
	prove t/*.t

fuzz: msgtest
	mkdir -p fuzz/run/in fuzz/run/out
	cp fuzz/request fuzz/run/in
	afl-fuzz -i fuzz/run/in -o fuzz/run/out -- ./msgtest

msgtest: src/msg.o
	cc -o $@ $<
randcat: aux/randcat.o
	cc -o $@ $<

src/msg.o: src/msg.c src/msg.tbl.inc

src/msg.tbl.inc: gen/tables
	./gen/tables > $@

.PHONY: all test fuzz
