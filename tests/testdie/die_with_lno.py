#!/usr/bin/env python3
# Generated by "pythonizer -v0 testdie/die_with_lno.pl" v1.028 run by JO2742 on Wed Mar  1 23:02:32 2023
# part of issue_s292: die with $. in the message
import builtins, perllib, sys

perllib.init_package("main")
builtins.__PACKAGE__ = "main"
fh = perllib.open_(f"{sys.argv[0]}", "r", checked=False)
line = perllib.readline_full(fh, "fh")
perllib.die("die with input")
