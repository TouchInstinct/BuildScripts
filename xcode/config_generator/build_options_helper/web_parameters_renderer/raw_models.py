# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from collections import namedtuple

OptionTuple = namedtuple('OptionTuple', [
    'key',
    'value',
    'enabled',
    'default'
])