#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from argument_parser import ArgumentParser

import yaml

from web_parameters_renderer import ParameterRenderer, Option
from ios_build_settings_renderer import XCConfigsRenderer, XCConfig

from core.models import BuildParameters, ParametersSet

import os

parser = ArgumentParser()
parser.configure()

args = parser.parse_args()

output_folder = os.path.abspath(os.path.expanduser(args.output_folder))

build_parameters = BuildParameters.from_dict(yaml.safe_load(args.build_parameters_path))

parameters_set = ParametersSet(active_parameters=build_parameters.all_parameters)

if args.platform == 'ios':
    parameters_set = parameters_set.update_parameters(build_parameters.ios_parameters)
elif args.platform == 'android':
    parameters_set = parameters_set.update_parameters(build_parameters.android_parameters)
else:
    raise ValueError("Unknown platform {}".format(args.platform))

if args.render == "ios_build_settings":
    xcconfigs = map(XCConfig.from_selectors, parameters_set.as_selectors(build_parameters.project_restrictions))
    XCConfigsRenderer("configs_data", xcconfigs).render_json_to_file_in_dir(output_folder)
elif args.render == "team_city_web_parameters":
    parameters_set = parameters_set.update_parameters(build_parameters.ci_parameters)
    active_parameters = parameters_set.active_parameters

    options_from_parameter = lambda p: [Option(key=value, value=value, enabled=True, default=p.default_value == value) for value in p.values]

    renderers = [ParameterRenderer(parameter.key, options_from_parameter(parameter)) for parameter in active_parameters]

    for r in renderers:
        r.render_json_to_file_in_dir(output_folder)
else:
    raise ValueError("Unknown render command {}".format(args.render))

print("Perameters renderer to {}".format(output_folder))
