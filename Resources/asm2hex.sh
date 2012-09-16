#!/bin/sh

# Print the usage
#if [ -z "$1" ] ; then
#		echo "Usage: asm2hex arch 'opcode'"
#		echo "| Where arch is ppc or i386. If no arch is specified"
#		echo "| then the architecture of the local machine is assumed."
#		echo "| The opcode should be in single quotes."
#		exit

# Create a temporary file which holds the assembly instruction; save the architecture	
if [ $# -eq 1 ]; then
    echo $1 > /tmp/instruction
    arch=$(arch)
else
    echo $2 > /tmp/instruction
    arch=$1
fi

ERRORFILE=/tmp/script.errors
# as assembles the instruction
as -arch $arch -W -o /tmp/asm2hex.tmp /tmp/instruction 2>$ERRORFILE

if [ -s "$ERRORFILE" ]; then
    # grep has spat the lines to stdout
    cat $ERRORFILE
else
    # otool disassembles the asm2hex.tmp file
    otool -tX -arch $arch /tmp/asm2hex.tmp | tail -n +1 | sed ``s/^[0-9a-zA-Z]*\ //g''   | sed ``s/\ //g''
fi