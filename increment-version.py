#!/usr/bin/env python3

# This increments the version number in two files. This will no be necessary once
# CI is set up wih variable replacement
import re
import os
import sys

def update(fn, start):
    old_v=None
    p = re.compile("1\.(\d+)")
    with open(fn, "r") as fin:
        with open(fn + "next", "w") as fout:

            def process(line):
                nonlocal old_v
                if line.startswith(start):
                    m = p.search(line)
                    assert m, line
                    assert old_v is None, old_v
                    old_v_s=m.group(1)
                    old_v=int(old_v_s)
                    new_v = old_v + 1
                    fout.write(f"{start}1.{new_v}\n")

                else:
                    fout.write(line)

            line = fin.readline()
            process(line)
            while line:
                line = fin.readline()
                process(line)
    os.replace(fn + "next", fn)

    return old_v

old_v = update("Makefile", "TAG ?= ")
old_v2= update("manifest/application.yaml.template", "    version: ")
assert  old_v==old_v2, f"The input files had different versions before this script ran; please revert and fix:{old_v} != {old_v2} "

