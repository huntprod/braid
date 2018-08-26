msgtest: src/msg.o
	cc -o $@ $<

src/msg.o: src/msg.c src/msg.tbl.inc

src/msg.tbl.inc: gen/tables
	./gen/tables > $@

