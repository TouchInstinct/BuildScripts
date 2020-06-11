# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

import json
import os

class ParameterRenderer:
    def __init__(self, name, options):
        self.name = name
        self.options_dict = {"options": [option._asdict() for option in options]}

    def render_to_json(self):
        return json.dumps(self.options_dict, indent=4)

    def render_json_to_file_in_dir(self, dir_path):
        file_name = "{}.json".format(self.name)
        file_path = os.path.join(dir_path, file_name)
        return json.dump(self.options_dict, open(file_path, 'w'), indent=4)

