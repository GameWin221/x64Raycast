nasm -f win64 src/main.asm -o main.o
:: Use x64 GNU MinGW linker: https://www.msys2.org/ or https://winlibs.com/
ld main.o -luser32 -lkernel32 -lGdi32 -o game.exe --strip-all --subsystem windows
del main.o