as -o printf.o printf.s
ld --entry main -o printf printf.o
./printf