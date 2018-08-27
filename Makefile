all: msgtest randcat
test:
	prove t/*.t

msgtest: src/msg.o
	cc -o $@ $<
randcat: aux/randcat.o
	cc -o $@ $<

src/msg.o: src/msg.c src/msg.tbl.inc

src/msg.tbl.inc: gen/tables
	./gen/tables > $@

.PHONY: all test
