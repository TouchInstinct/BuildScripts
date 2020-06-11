# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from collections import namedtuple

from .restriction import Restriction
from .parameter import Parameter

BuildParametersTuple = namedtuple('BuildParametersTuple', [
    'all_parameters',
    'project_restrictions',
    'ci_parameters',
    'ios_parameters',
    'android_parameters',
])

class BuildParameters(BuildParametersTuple):
    @staticmethod
    def from_dict(dict_obj):
        return BuildParameters(
            all_parameters=list(map(Parameter.from_dict, dict_obj["all_parameters"])),
            project_restrictions=list(map(Restriction.from_dict, dict_obj["project_restrictions"])),
            ci_parameters=list(map(Parameter.from_dict, dict_obj["ci_parameters"])),
            ios_parameters=list(map(Parameter.from_dict, dict_obj["ios_parameters"])),
            android_parameters=list(map(Parameter.from_dict, dict_obj["android_parameters"]))
        )