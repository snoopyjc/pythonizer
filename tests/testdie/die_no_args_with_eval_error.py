#!/usr/bin/env python3
# Generated by "pythonizer -v0 testdie/die_no_args_with_eval_error.pl" v1.028 run by JO2742 on Wed Mar  1 23:02:25 2023
# part of issue_s292: die w/o args with eval_error
# If LIST was empty or made an empty string, and $@ already contains an exception value (typically from a previous eval), then that value is reused after appending "\t...propagated". This is useful for propagating exceptions
import builtins, perllib

perllib.init_package("main")
builtins.__PACKAGE__ = "main"
perllib.EVAL_ERROR = "exception value"
perllib.die()
