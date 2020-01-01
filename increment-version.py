import re
import os
import sys

def update(fn, start):
    p = re.compile("1\.(\d+)")
    with open(fn, "r") as fin:
        with open(fn + "next", "w") as fout:

            def process(line):
                if line.startswith(start):
                    m = p.search(line)
                    assert m, line
                    old_v=m.group(1)
                    v = int(old_v) + 1
                    fout.write(f"{start}1.{v}\n")

                else:
                    fout.write(line)

            line = fin.readline()
            process(line)
            while line:
                line = fin.readline()
                process(line)
    os.replace(fn + "next", fn)


update("Makefile", "TAG ?= ")
update("manifest/application.yaml.template", "    version: ")
