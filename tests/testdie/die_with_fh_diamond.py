#!/usr/bin/env python3
# Generated by "pythonizer -v0 testdie/die_with_fh_diamond.pl" v1.030 run by joe on Wed Apr 19 09:52:31 2023
# Implied pythonizer options: -m
# part of issue_s292: die with $. in the message, <>
import builtins, perllib, sys

perllib.init_package("main")
sys.argv = perllib.Array(sys.argv)
builtins.__PACKAGE__ = "main"
sys.argv.append(sys.argv[0])
line = perllib.fileinput_next()
perllib.die("die with diamond fh input")
