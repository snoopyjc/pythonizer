
def _method_call(cls_or_obj, methodname, *args, **kwargs):
    """Call a method by name in a class that can also be specified by name"""
    try:
        if methodname in _PYTHONIZER_KEYWORDS:
            methodname += '_'
        method = getattr(cls_or_obj, methodname)
        if hasattr(method, '__func__'):
            method = method.__func__
        return method(cls_or_obj, *args, **kwargs)
    except AttributeError:
        if isinstance(cls_or_obj, str):
            cls_or_obj = cls_or_obj.replace('::', '.')
            if cls_or_obj in _PYTHONIZER_KEYWORDS:
                cls_or_obj += '_'
            if hasattr(builtins, cls_or_obj):
                cls_or_obj = getattr(builtins, cls_or_obj)
                method = getattr(cls_or_obj, methodname)
                if hasattr(method, '__func__'):
                    method = method.__func__
                return method(cls_or_obj, *args, **kwargs)
    except TypeError:
        if callable(methodname):
            method = methodname
            if isinstance(cls_or_obj, str):
                cls_or_obj = cls_or_obj.replace('::', '.')
                if cls_or_obj in _PYTHONIZER_KEYWORDS:
                    cls_or_obj += '_'
            if hasattr(method, '__func__'):
                method = method.__func__
            return method(cls_or_obj, *args, **kwargs)

    _cluck(f"Can't locate object method \"{methodname}\" via package \"{_str(cls_or_obj)}\"", skip=2)


