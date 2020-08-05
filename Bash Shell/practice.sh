#!/usr/bin/env bash

function test () {

  barry=("$@")
  echo "barry is ${barry[@]}"

  echo "length is ${#barry[@]}"
  echo "1 arg is ${barry[1]}"
}

arrary=("a" "b" "c")

test ${arrary[@]}