require_relative "config_renderer"
#
# Usage:  render_xcconfigs.rb <configurations.yaml> <build_parameters.yaml> [<ouptut folder>]
#
# Result: Adds .xcconfig files to ouptut folder.
#         Files are only being added and changed, not removed!
#         It is recommended to remove old .xcconfig files before running this script.
#

# Input files paths
configurations_file_path = ARGV[0]
build_parameters_path = ARGV[1]
configs_folder_name = ARGV[2] || "TargetConfigurations"

ConfigRenderer.new(configurations_file_path, build_parameters_path, configs_folder_name).render_xconfigs()
