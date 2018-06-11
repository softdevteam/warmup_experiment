#!/bin/sh
#
# ChakraCore's command line handling doesn't sit well with Krun (-end-args
# means it cannot simply append arguments on to the end of the invocation).
# This wrapper script exposes `ch` in a more regular way, so that we pass
# command line arguments in the usual manner.

script_name=$1
shift

%%CHAKRA_DIR%%/out/Release/ch ${script_name} -args $@ -endargs
