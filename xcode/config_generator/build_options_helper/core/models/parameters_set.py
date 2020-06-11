# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from collections import namedtuple

from .selector import Selector

ParametersSetTuple = namedtuple('ParametersSetTuple', [
    'active_parameters',
])

class ParametersSet(ParametersSetTuple):
    def filter_using_restrictions_and_selectors(self, restrictions, selectors):
        new_parameters = ParametersSet.__filter_parameters_using_restrictions_and_selectors(self.active_parameters, restrictions, selectors)

        return ParametersSet(active_parameters=new_parameters)

    def update_parameters(self, parameters):
        parameters_dict = { p.key : p for p in parameters }
        parameters_dict_keys = parameters_dict.keys()

        # update & keep ordering
        new_active_parameters = [parameters_dict[p.key] if p.key in parameters_dict_keys else p for p in self.active_parameters]

        return ParametersSet(active_parameters=new_active_parameters)

    @staticmethod
    def __filter_parameters_using_restrictions_and_selectors(parameters, restrictions, selectors):
        active_restrictions = filter(lambda r: r.is_active_for_selectors(selectors), restrictions)

        parameters_keys = list(map(lambda p: p.key, parameters))

        parameters_from_restrictions = { parameter.key : parameter for restriction in active_restrictions for parameter in restriction.set if parameter.key in parameters_keys }

        # replace with restriction parameters and keep original ordering
        return [parameters_from_restrictions.get(p.key, p) for p in parameters]

    @staticmethod
    def __difference_for_parameters(parameters, active_parameters):
        parameters_keys = list(map(lambda p: p.key, parameters))

        return list(filter(lambda p: p.key not in parameters_keys, active_parameters))

    def as_selectors(self, project_restrictions):
        non_empty_active_parameters = list(filter(lambda p: len(p.values) > 0, self.active_parameters))

        if len(non_empty_active_parameters) > 0:
            return list(ParametersSet.__as_selectors_recursive([], non_empty_active_parameters[0], non_empty_active_parameters[1:], non_empty_active_parameters, project_restrictions))
        else:
            return []

    @staticmethod
    def __as_selectors_recursive(head_selectors, current_parameter, tail_parameters, all_parameters, project_restrictions):
        if len(tail_parameters) == 0:
            for parameter_value in current_parameter.values:
                current_selector = Selector(key=current_parameter.key, value=parameter_value)
                new_head_selectors = head_selectors + [current_selector]

                all_parameters_filtered = ParametersSet.__filter_parameters_using_restrictions_and_selectors(all_parameters, project_restrictions, new_head_selectors)

                parameters_selectors = { selector for parameter in all_parameters_filtered for selector in parameter.values_selectors() }

                if set(new_head_selectors).issubset(parameters_selectors):
                    yield new_head_selectors

            return

        for current_parameter_value in current_parameter.values:
            current_selector = Selector(key=current_parameter.key, value=current_parameter_value)
            new_head_selectors = head_selectors + [current_selector]

            new_tail_parameters = ParametersSet.__filter_parameters_using_restrictions_and_selectors(tail_parameters[1:], project_restrictions, new_head_selectors)

            for selectors in ParametersSet.__as_selectors_recursive(new_head_selectors, tail_parameters[0], new_tail_parameters, all_parameters, project_restrictions):
                yield selectors

