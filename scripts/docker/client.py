"""
    Client.py

    Usage:

        $ cat expected.json | python client.py URI

    Prints any differences between the JSON on specified
    URI and the given JSON in stdin. No output == no differences.

    Test (requires pytest):

        $ python3 -m pytest client.py
"""

import difflib
import functools
import json
import requests
import sys
import time
import typing

import unittest


try:
    import pytest
except ImportError:
    # no test
    pytest = None


def _diff(a: str, b: str) -> typing.Iterator[str]:
    """ Returns a -/+ comparison of `a` and `b` """
    differ = difflib.Differ()
    return differ.compare(
        *(
            i.splitlines(keepends=True)
            for i in (a, b)
        )
    )


class MisMatch(AssertionError):
    def __init__(self, a, b):
        self.a = a
        self.b = b

    @staticmethod
    def _render(d: dict) -> str:
        return json.dumps(d, indent=2, sort_keys=True)

    @property
    def got(self) -> str:
        return self._render(self.a)

    @property
    def expected(self) -> str:
        return self._render(self.b)

    def __str__(self) -> str:
        result = _diff(self.got, self.expected)
        return "AssertionError: diff:\n {}".format(
                "".join(result)
        )


class Tester(unittest.TestCase):

    def is_equal(self, a, b):
        try:
            l1 = a["results"].sort(key=lambda e: e["string"])
            l2 = b["results"].sort(key=lambda e: e["string"])
            self.assertEqual(a, b)
            return True
        except Exception as e:
            print(str(e))
            return False

def check(actual_data, expected_data):
    """ Checks URI for expected data,
        raises Mismatch if there are differences.
    """

    # simple comparison now, could be more restrictive
    tester = Tester()
    if not tester.is_equal(actual_data, expected_data):
        raise MisMatch(actual_data, expected_data)


def test_check():
    # should work
    check("a", "a")
    with pytest.raises(MisMatch):
        # a != b so should fail
        check("b", "a")


def retry(func: typing.Callable,
          excs: typing.Tuple[Exception],
          args=[], kwargs={}, attempts=5, sleep=1):
    """ Retry callable `func` when any Exception is in `excs` is raised.
        Pass `attempts` for the amount of retries, pass `sleep` in seconds
        to enforce a back-off.
    """
    attempt = error = 0
    while attempt < attempts:
        attempt += 1
        try:
            return func(*args, **kwargs)
        except excs as exc:
            error = exc
        time.sleep(sleep)
    if error:
        # We arrive here in case we got an expected error, raise it.
        raise error


def test_retry():
    a = []

    def _func(arg, a, kwarg):
        a.append(1)
        if len(a) > 3:
            raise RuntimeError
        assert (arg, kwarg) == ("foo", "bar")

    retry_p = functools.partial(
        retry, _func, excs=(AssertionError,), attempts=2, sleep=0.1
    )

    retry_p(args=["foo", a], kwargs={'kwarg': 'bar'})
    assert len(a) == 1

    with pytest.raises(AssertionError):
        retry_p(args=["asd", a], kwargs={'kwarg': 'bar'})
    assert len(a) == 3

    with pytest.raises(RuntimeError):
        retry_p(args=["asd", a], kwargs={'kwarg': 'bar'})
    assert len(a) == 4


def main(uri, expected_json):
    """ application code """
    expected_data = json.loads(expected_json)
    retry(
        lambda: check(requests.get(uri).json(), expected_data),
        excs=(MisMatch,)
    )


if __name__ == "__main__":
    """ interface code """
    uri = sys.argv[1]
    try:
        main(
            uri,
            expected_json=sys.stdin.read()
        )
    except Exception as e:
        print(e)
