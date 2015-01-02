TARGET = 
INCS = -I/home/hadoop/lua-5.2.0/src
LIBS = -llua -lm -ldl
interpreter:
	gcc -Wall -o $@ $@.c $(LIBS) $(INCS)

stack:
	gcc -Wall -o $@ $@.c $(LIBS) 	
clean:
	rm interpreter stack
