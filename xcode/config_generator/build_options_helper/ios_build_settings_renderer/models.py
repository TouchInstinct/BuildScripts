# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from .raw_models import *
from core.models import Selector

class XCConfig(XCConfigTuple):

    DISTIBUTION_TYPE_KEY = "DISTRIBUTION_TYPE"
    BUILD_TYPE_KEY = "BUILD_TYPE"

    @staticmethod
    def from_selectors(selectors):
        selectors_dict = XCConfig.__make_dict_from_selectors(selectors)

        distibution_type_value = selectors_dict.get(XCConfig.DISTIBUTION_TYPE_KEY, None)

        is_app_store_config = distibution_type_value.lower() == "AppStore".lower()
        build_type_value = selectors_dict.get(XCConfig.BUILD_TYPE_KEY, None)
        build_type = distibution_type_value.lower() if is_app_store_config else build_type_value.lower()

        compatability_selectors = map(XCConfig.__modify_selector_if_needed, selectors)

        return XCConfig(
            name="".join(map(lambda s: s.value, compatability_selectors)),
            account_type=distibution_type_value,
            build_type=build_type,
            xcconfig_options=map(lambda f: f(selectors_dict), [
                XCConfigOption.swift_active_compilation_conditions,
                XCConfigOption.debug_information_format,
                XCConfigOption.validate_product,
                XCConfigOption.enable_testability,
                XCConfigOption.code_sign_identity,
                XCConfigOption.gcc_optimization_level,
                XCConfigOption.swift_optimization_level,
                XCConfigOption.swift_compilation_mode
            ])
        )

    @staticmethod
    def __make_dict_from_selectors(selectors):
        # compatibility mode
        return { s.key : (XCConfig.__account_type_from_distribution_type(s.value) if s.key == XCConfig.DISTIBUTION_TYPE_KEY else s.value) for s in selectors }

        # normal mode
        # return { s.key : s.value for s in selectors }

    @staticmethod
    def __modify_selector_if_needed(selector):
        # compatibility mode
        if selector.key == XCConfig.DISTIBUTION_TYPE_KEY:
            return Selector(key=selector.key, value=XCConfig.__account_type_from_distribution_type(selector.value))
        else:
            return selector

        # normal mode
        # return selector

    @staticmethod
    def __account_type_from_distribution_type(distibution_type):
        if distibution_type == "Local":
            return "Standard"
        elif distibution_type == "Firebase":
            return "Enterprise"
        elif distibution_type == "Store":
            return "AppStore"

    def _asdict(self):
        return {
            'name': self.name,
            'account_type': self.account_type,
            'build_type': self.build_type,
            'xcconfig_options': [o._asdict() for o in self.xcconfig_options]
        }


class XCConfigOption(XCConfigOptionTuple):
    @staticmethod
    def swift_active_compilation_conditions(selectors_dict):
        return XCConfigOption(
            key="SWIFT_ACTIVE_COMPILATION_CONDITIONS",
            value=" ".join(map(lambda sv: sv.upper(), selectors_dict.values()))
        )

    @staticmethod
    def debug_information_format(selectors_dict):
        return XCConfigOption.__from_key_and_value_based_on_value_in_selectors("DEBUG_INFORMATION_FORMAT", "dwarf", "dwarf-with-dsym", selectors_dict)

    @staticmethod
    def validate_product(selectors_dict):
        return XCConfigOption.__from_key_and_value_based_on_value_in_selectors("VALIDATE_PRODUCT", "NO", "YES", selectors_dict)

    @staticmethod
    def enable_testability(selectors_dict):
        return XCConfigOption.__from_key_and_value_based_on_value_in_selectors("ENABLE_TESTABILITY", "YES", "NO", selectors_dict)

    @staticmethod
    def code_sign_identity(selectors_dict):
        return XCConfigOption.__from_key_and_value_based_on_value_in_selectors("CODE_SIGN_IDENTITY", "iPhone Developer", "iPhone Distribution", selectors_dict, "Standard")

    @staticmethod
    def gcc_optimization_level(selectors_dict):
        return XCConfigOption.__from_key_and_value_based_on_value_in_selectors("GCC_OPTIMIZATION_LEVEL", "0", "s", selectors_dict)

    @staticmethod
    def swift_optimization_level(selectors_dict):
        return XCConfigOption.__from_key_and_value_based_on_value_in_selectors("SWIFT_OPTIMIZATION_LEVEL", "-Onone", "-O", selectors_dict)

    @staticmethod
    def swift_compilation_mode(selectors_dict):
        return XCConfigOption.__from_key_and_value_based_on_value_in_selectors("SWIFT_COMPILATION_MODE", "singlefile", "wholemodule", selectors_dict)

    @staticmethod
    def __from_key_and_value_based_on_value_in_selectors(key, value_if_contains, otherwise_value,
                                                         selectors_dict, expected_value="Debug"):
        return XCConfigOption(
            key=key,
            value=value_if_contains if expected_value.upper() in map(lambda sv: sv.upper(), selectors_dict.values()) else otherwise_value
        )
