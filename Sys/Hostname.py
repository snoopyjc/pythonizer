#!/usr/bin/env python3
# Generated by "pythonizer -M -v 0 -s ./PyModules/Sys/Hostname.pm" v0.964 run by JO2742 on Sat Mar 12 16:24:25 2022
# Edited by snoopyjc

__author__ = """Joe Cool"""
___email__ = 'snoopyjc@gmail.com'
__version__ = '1.020'

import signal, re, perllib, builtins, os

_str = lambda s: "" if s is None else str(s)
_locals_stack = []
perllib.init_package("Sys.Hostname")


def hostname():
    """Implementation of Sys::Hostname::hostname function: Try every conceivable way to get hostname.  Usage:

           from Sys.Hostname import hostname

           host = hostname()
    """

    rslt = None

    # method 1 - we already know it
    if (Sys.Hostname.host) is not None:
        return Sys.Hostname.host

    # method 1' - try to ask the system

    #if "ghname" in globals():
    try:
        import socket
        Sys.Hostname.ghname = socket.gethostname
        Sys.Hostname.host = Sys.Hostname.ghname()
    except Exception:
        pass

    if (Sys.Hostname.host) is not None:
        return Sys.Hostname.host

    if perllib.os_name() == "MSWin32":
        #[Sys.Hostname.host] = perllib.list_of_n(Sys.Hostname.gethostbyname("localhost"), 1)
        try:
            import platform
            Sys.Hostname.host = platform.node()
        except Exception:
            pass
        if Sys.Hostname.host is None:
            Sys.Hostname.host = perllib.run_s("hostname 2> NUL")
            Sys.Hostname.host = Sys.Hostname.host.rstrip("\n")

        return Sys.Hostname.host
    else:
        try:
            _locals_stack.append(os.environ)
            # is anyone going to make it here?

            os.environ = os.environ.copy()
            os.environ["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"  # Paranoia.

            # method 2 - syscall is preferred since it avoids tainting problems
            # XXX: is it such a good idea to return hostname untainted?
#            try:
#                try:
#                    _locals_stack.append(perllib.TRACEBACK)
#                    perllib.TRACEBACK = 0
#                    perllib.import_(globals(), "syscall.ph")
#                    Sys.Hostname.host = "\0" * 65  ## preload scalar
#                    perllib.num(
#                        Sys.Hostname.syscall(
#                            Sys.Hostname.SYS_gethostname(_args), Sys.Hostname.host, 65
#                        )
#                    ) == 0
#
#                finally:
#                    perllib.TRACEBACK = _locals_stack.pop()
#
#                # method 2a - syscall using systeminfo instead of gethostname
#                #           -- needed on systems like Solaris
#
#                perllib.EVAL_ERROR = None
#            except Exception as _e:
#                perllib.EVAL_ERROR = perllib.exc(_e)
#
#            _eval_result86 = None
            try:
                import platform
                Sys.Hostname.host = platform.node()
                if Sys.Hostname.host:
                    return Sys.Hostname.host
            except Exception:
                pass

#            try:
#                try:
#                    _locals_stack.append(perllib.TRACEBACK)
#                    perllib.TRACEBACK = 0
#                    perllib.import_(globals(), "sys/syscall.ph")
#                    perllib.import_(globals(), "sys/systeminfo.ph")
#                    Sys.Hostname.host = "\0" * 65  ## preload scalar
#                    perllib.num(
#                        Sys.Hostname.syscall(
#                            Sys.Hostname.SYS_systeminfo(_args),
#                            Sys.Hostname.SI_HOSTNAME(_args),
#                            Sys.Hostname.host,
#                            65,
#                        )
#                    ) != -1
#
#                finally:
#                    perllib.TRACEBACK = _locals_stack.pop()
#
#                # method 3 - trusty old hostname command
#
#                perllib.EVAL_ERROR = None
#            except Exception as _e:
#                perllib.EVAL_ERROR = perllib.exc(_e)
#
#            _eval_result95 = None
            try:
                try:
                    _locals_stack.append(perllib.TRACEBACK)
                    _locals_stack.append(signal.getsignal(signal.SIGCHLD))
                    perllib.TRACEBACK = 0
                    signal.signal(signal.SIGCHLD, signal.SIG_IGN)
                    Sys.Hostname.host = perllib.run_s("(hostname) 2>/dev/null")  # BSDish
                    if Sys.Hostname.host:
                        Sys.Hostname.host = Sys.Hostname.host.translate(str.maketrans("", "", "\x00\r\n"))
                        return Sys.Hostname.host

                finally:
                    signal.signal(signal.SIGCHLD, _locals_stack.pop())
                    perllib.TRACEBACK = _locals_stack.pop()

                # method 4 - use POSIX::uname(), which strictly can't be expected to be
                # correct

                perllib.EVAL_ERROR = None
            except Exception as _e:
                perllib.EVAL_ERROR = perllib.exc(_e)

            _eval_result103 = None
            try:
                try:
                    _locals_stack.append(perllib.TRACEBACK)
                    perllib.TRACEBACK = 0
                    pass  # SKIPPED: 	require POSIX;
                    Sys.Hostname.host = (POSIX.uname())[1]
                    if Sys.Hostname.host:
                        return Sys.Hostname.host

                finally:
                    perllib.TRACEBACK = _locals_stack.pop()

                # method 5 - sysV uname command (may truncate)

                perllib.EVAL_ERROR = None
            except Exception as _e:
                perllib.EVAL_ERROR = perllib.exc(_e)

            _eval_result110 = None
            try:
                try:
                    _locals_stack.append(perllib.TRACEBACK)
                    perllib.TRACEBACK = 0
                    Sys.Hostname.host = perllib.run_s("uname -n 2>/dev/null")  ## sysVish

                finally:
                    perllib.TRACEBACK = _locals_stack.pop()

                # bummer

                perllib.EVAL_ERROR = None
            except Exception as _e:
                perllib.EVAL_ERROR = perllib.exc(_e)

            # remove garbage

            Sys.Hostname.host = Sys.Hostname.host.translate(str.maketrans("", "", "\x00\r\n"))
            return Sys.Hostname.host

        finally:
            os.environ = _locals_stack.pop()


Sys.Hostname.hostname = hostname

Sys.Hostname.VERSION = perllib.init_global("Sys.Hostname", "VERSION", "")
Sys.Hostname.host = perllib.init_global("Sys.Hostname", "host", None)

builtins.__PACKAGE__ = "Sys.Hostname"

# SKIPPED: use strict;

# SKIPPED: use Carp;

# SKIPPED: require Exporter;

Sys.Hostname.ISA = "Exporter".split()
Sys.Hostname.EXPORT = "hostname".split()

#perllib.WARNING = 1

if True:  # BEGIN:
    Sys.Hostname.VERSION = "1.23"
#    for _ in range(1):
#        try:
#            _locals_stack.append(perllib.TRACEBACK)
#            perllib.TRACEBACK = 0
#            try:
#                import XSLoader as _XSLoader
#
#                XSLoader.load()
#                perllib.EVAL_ERROR = None
#            except Exception as _e:
#                perllib.EVAL_ERROR = perllib.exc(_e)
#
#            if perllib.EVAL_ERROR:
#                print(perllib.EVAL_ERROR)
#
#        finally:
#            perllib.TRACEBACK = _locals_stack.pop()
