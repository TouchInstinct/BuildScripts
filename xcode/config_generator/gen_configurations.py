#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from itertools import chain
import json

distribution_options = ["Enterprise", "Standard"]
server_type_options = ["Mock", "Touchin", "Customer"]
server_environment_options = ["Dev", "Test", "Stage", "Prod"]
ssl_pinning_options = ["WithSSLPinning", "WithoutSSLPinning"]
build_type_options = ["Debug", "Release"]

all_options = [
    distribution_options,
    server_type_options,
    server_environment_options,
    ssl_pinning_options,
    build_type_options
]

def combine_string_with_options(all_options, string="", applied_options=[]):
    if len(all_options) == 0:
        yield string, applied_options
        return

    for current_option in chain.from_iterable(all_options[:1]):
        for result_tuple in combine_string_with_options(all_options[1:], string + current_option, applied_options + [current_option]):
            yield result_tuple

    yield ("AppStoreRelease", ['AppStore', 'Customer', 'Prod', 'WithSSLPinning', 'Release'])

def make_config_dict(args):
    config_name, applied_options = args

    if "Enterprise" in applied_options:
        account_type = "Enterprise"
    elif "Standard" in applied_options:
        account_type = "Standard"
    else:
        account_type = "AppStore"

    if "Debug" in applied_options:
        build_type = "debug"
    elif "AppStore" in applied_options:
        build_type = "appstore"
    else:
        build_type = "release"

    return {
        "name": config_name,
        "build_type": build_type,
        "account_type": account_type,
        "xcconfig_options": [
            {
                "key": "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
                "value": " ".join(map(lambda option: option.upper(), applied_options))
            },
            {
                "key": "DEBUG_INFORMATION_FORMAT",
                "value": "dwarf" if "Debug" in applied_options else "dwarf-with-dsym"
            },
            {
                "key": "VALIDATE_PRODUCT",
                "value": "NO" if "Debug" in applied_options else "YES"
            },
            {
                "key": "ENABLE_TESTABILITY",
                "value": "YES" if "Debug" in applied_options else "NO"
            },
            {
                "key": "CODE_SIGN_IDENTITY",
                "value": "iPhone Developer" if account_type == "Standard" else "iPhone Distribution"
            },
            {
                "key": "GCC_OPTIMIZATION_LEVEL",
                "value": "0" if "Debug" in applied_options else "s"
            },
            {
                "key": "SWIFT_OPTIMIZATION_LEVEL",
                "value": "-Onone" if "Debug" in applied_options else "-O"
            },
            {
                "key": "SWIFT_COMPILATION_MODE",
                "value": "singlefile" if "Debug" in applied_options else "wholemodule"
            }
        ]
    }


config_dicts = map(make_config_dict, combine_string_with_options(all_options))

print(json.dumps({"configurations": config_dicts}, indent=4))
