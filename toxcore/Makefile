
TARGET = libtoxcore.a

all: $(TARGET)

libtoxcore.o: toxcore_amalgamation.c
	$(CC) -c -o $@ $< -O2 -Wno-discarded-qualifiers -fPIC -Wl,-Bstatic $(shell pkg-config --cflags --libs libsodium x264) -Wl,-Bdynamic $(shell pkg-config --cflags --libs opus vpx libavcodec libavutil) -pthread

$(TARGET): libtoxcore.o
	$(AR) rcs $@ $^



