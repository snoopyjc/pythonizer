#!/usr/bin/env python3
# Generated by "pythonizer -M -v0 subdir/subsubdir/Util.pm" v1.028 run by JO2742 on Wed Mar  1 23:11:40 2023
# part of issue_s225
import builtins, perllib
from Exporter import import_

builtins.__PACKAGE__ = "subsubdir.Util"
Exporter.import_("Exporter", "import")
perllib.init_package("subsubdir.Util")


def myutil(*_args):
    return perllib.num(_args[0]) + 1


subsubdir.Util.myutil = myutil

builtins.__PACKAGE__ = "subsubdir.Util"

subsubdir.Util.import_ = import_
# SKIPPED: require 5.004;

subsubdir.Util.VERSION_v = "4.54"
subsubdir.Util.EXPORT_a = "myutil".split()
