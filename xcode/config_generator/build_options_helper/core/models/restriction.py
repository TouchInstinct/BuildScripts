# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from collections import namedtuple

from .selector import Selector
from .parameter import Parameter

RestrictionTuple = namedtuple('RestrictionTuple', [
    'when',
    'set',
])

class Restriction(RestrictionTuple):
    @staticmethod
    def from_dict(dict_obj):
        return Restriction(
            when=frozenset(map(Selector.from_dict, dict_obj["when"])),
            set=list(map(Parameter.from_dict, dict_obj["set"])),
        )

    def is_active_for_selectors(self, selectors):
        return not frozenset(selectors).isdisjoint(self.when)