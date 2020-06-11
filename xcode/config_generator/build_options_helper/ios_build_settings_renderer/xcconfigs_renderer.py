# -*- coding: utf-8 -*-

from __future__ import unicode_literals # python 2/3 support

import json
import os

class XCConfigsRenderer:
    def __init__(self, name, xcconfigs):
        self.name = name
        self.xcconfig_dicts = [xcconfig._asdict() for xcconfig in xcconfigs]

    def render_to_json(self):
        return json.dumps(self.xcconfig_dicts, indent=4)

    def render_json_to_file_in_dir(self, dir_path):
        file_name = "{}.json".format(self.name)
        file_path = os.path.join(dir_path, file_name)
        return json.dump(self.xcconfig_dicts, open(file_path, 'w'), indent=4)
