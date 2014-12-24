TARGET = interpreter
INCS = -I/home/hadoop/lua-5.2.0/src
LIBS = -llua -lm -ldl
all:
	gcc -Wall -o $(TARGET) $(TARGET).c $(LIBS) $(INCS)
clean:
	rm $(TARGET)
