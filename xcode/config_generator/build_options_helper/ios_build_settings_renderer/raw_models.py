# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from collections import namedtuple

XCConfigOptionTuple = namedtuple('XCConfigOptionTuple', [
    'key',
    'value'
])

XCConfigTuple = namedtuple('XCConfigTuple', [
    'name',
    'account_type',
    'build_type',
    'xcconfig_options'
])