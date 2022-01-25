
def _read(fh, var, length, offset=0, need_len=False):
    """Read length bytes from the fh, and return the result to store in var
       if need_len is False, else return a tuple with the result
       and the length read"""
    global OS_ERROR, TRACEBACK, AUTODIE
    if var is None:
        var = ''
    try:
        s = fh.read(length)
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        if need_len:
            return (var, None)
        return var

    ls = len(s)
    lv = len(var)
    if offset < 0:
        offset += lv
    if offset:
        if need_len:
            return (var[:offset] + ('\0' * (offset-lv)) + s, ls)
        else:
            return var[:offset] + ('\0' * (offset-lv)) + s
    if need_len:
        return (s, ls)
    return s
