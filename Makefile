ZIG ?= zig
TARGET := bin/luaapi.asi
DEBUG_TARGET := bin/luaapi-debug.asi
SRCS := src/main.c 
CFLAGS := -Ivendor/luajit/src -DLUAJIT_STATIC
LDFLAGS := -lc
LUAJIT_LIB := vendor/luajit/src/libluajit.a

.PHONY: all clean install debug format lua

all: $(TARGET)

debug: $(DEBUG_TARGET)

$(TARGET): $(SRCS) $(LUAJIT_LIB)
	@mkdir -p $(dir $@)
	$(ZIG) build-lib -target x86-windows-gnu -dynamic -O ReleaseSmall --name luaapi \
		-femit-bin=$@ $(CFLAGS) $(LDFLAGS) $(SRCS) $(LUAJIT_LIB)

$(DEBUG_TARGET): $(SRCS) $(LUAJIT_LIB)
	@mkdir -p $(dir $@)
	$(ZIG) build-lib -target x86-windows-gnu -dynamic -O Debug --name luaapi-debug \
		-femit-bin=$@ $(CFLAGS) $(LDFLAGS) $(SRCS) $(LUAJIT_LIB)

clean:
	rm -f bin/* $(TARGET) $(DEBUG_TARGET)

format:
	clang-format -i src/*

lua:
	cd vendor/luajit &&	make CC="zig cc -target x86-windows-gnu -m32" BUILDMODE=static TARGET_SYS=Windows

install: $(TARGET)
	mkdir -p ~/.wine/drive_c/Guild
	cp $(TARGET) ~/.wine/drive_c/Guild/
	cp -r scripts/lua ~/.wine/drive_c/Guild/


