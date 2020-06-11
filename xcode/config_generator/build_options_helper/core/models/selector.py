# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from collections import namedtuple

SelectorTuple = namedtuple('SelectorTuple', [
    'key',
    'value',
])

class Selector(SelectorTuple):
    @staticmethod
    def from_dict(dict_obj):
        return Selector(**dict_obj)

    def __eq__(self, obj):
        return isinstance(obj, Selector) and \
            obj.key == self.key and \
            obj.value == self.value

    def __hash__(self):
        return hash((self.key, self.value))