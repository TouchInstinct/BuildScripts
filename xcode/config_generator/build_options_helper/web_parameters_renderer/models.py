# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

from .raw_models import *

class Option(OptionTuple):
    def _asdict(self):
        original_dict = super(Option, self)._asdict()
        # remove records with None values
        return {k: v for k, v in original_dict.items() if v is not None}


