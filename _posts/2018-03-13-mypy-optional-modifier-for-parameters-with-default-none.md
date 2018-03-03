---
title: "MyPy 'Optional' Modifier for Parameters with Default Value 'None'"
---
For a Python function with a parameter with default value `None`, what is the effect of marking that parameter as `Optional`?

`def f(a: Optional[str] = None)` seemed overly verbose to me, because I didn't understand why "Optional" wouldn't just be inferred from `def f(a: str = None)`.

It turns out that, as of today, "Optional" *is* inferred in the second definition, such that the second def is equal to the first. However, there is [discussion about removing this implicit Optional'(]ttps://github.com/python/typing/issues/275). One key argument for the removal is that "inn all other contexts, `a: int = None` is a type error.

I put together a small example of the differences between the two defs, when using the --strict-optional (which will eventually be default in mypy) and  --no-implicit-optional flags for mypy:

```python
# test.py
from typing import Optional

def foo(x: Optional[str]):
    print(x)

foo(None)
foo()

def bar(y: Optional[str] = None):
    print(y)

bar(None)
bar()

def baz(z: str = None):
    print(z)

baz(None)
baz()
```

Results:

```
⇒  pipenv run mypy test.py
test.py:8: error: Too few arguments for "foo"

⇒  pipenv run mypy test.py --strict-optional  # strict-optional will eventually be default for mypy
test.py:8: error: Too few arguments for "foo"

⇒  pipenv run mypy test.py --strict-optional --no-implicit-optional
test.py:8: error: Too few arguments for "foo"
test.py:16: error: Incompatible default for argument "z" (default has type "None", argument has type "str")
test.py:19: error: Argument 1 to "baz" has incompatible type "None"; expected "str"



⇒  pipenv run python --version
Python 3.4.7
⇒  pipenv run mypy --version
mypy 0.570
```
