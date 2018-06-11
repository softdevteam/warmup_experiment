#!/bin/sh
#
# ChakraCore doesn't support command line arguments or environment vars, so we
# have to write a script containing the iteration runner arguments. The script
# is the loaded using `LoadScriptFile` inside the iteration runner.

script_out=/tmp/chakra_args.js
script_name=$1
shift


echo "this.arguments = {};" > ${script_out}
for idx in `seq 0 $(($# - 1))`; do
    echo "this.arguments[${idx}] = \"$1\";" >> ${script_out}
    shift
done

%%CHAKRA_DIR%%/out/Release/ch ${script_name}

rm ${SCRIPT_OUT}
