# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from collections import namedtuple

from .selector import Selector

ParameterTuple = namedtuple('ParameterTuple', [
    'key',
    'values',
    'default_value',
])

class Parameter(ParameterTuple):
    @staticmethod
    def from_dict(dict_obj):
        return Parameter(
            key=dict_obj["key"],
            values=dict_obj["values"],
            default_value=dict_obj.get("default_value")
        )

    def values_selectors(self):
        return [Selector(key=self.key, value=value) for value in self.values]