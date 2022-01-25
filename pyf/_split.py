
def _split(pattern, string, maxsplit=0, flags=0):
    """Split function in perl is similar to re.split but not quite
       the same - this function makes it the same"""
    result = re.split(pattern, string, max(0, maxsplit), flags)
    if maxsplit >= -1:  # We subtracted one from what the user specifies
        limit = len(result)
        # Empty results at the end are eliminated
        for i in range(limit-1, -1, -1):
            if result[i] == '':
                limit -= 1
            else:
                break

        return result[:limit]

    return result

