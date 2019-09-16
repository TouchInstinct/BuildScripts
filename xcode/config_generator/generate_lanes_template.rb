require 'json'

# call python script and generate configs to config file
system("python gen_configurations.py > configs_data.json")

# generate fastlane lane block
def generate_lane(lane_name)
    first_line = "lane :" + lane_name + " do |options|\n"
    second_line = "\tbuildConfiguration(options)\n"
    third_line = "end\n"
    separator = "\n"
    return first_line + second_line + third_line + separator
end

# open configs for rendering
configs = JSON.load(File.open("configs_data.json"))["configurations"]

# map configs to lanes
lanes = configs.map { |config| generate_lane(config["name"]) }

# make all lanes uniq
lanes.uniq!

# write lanes to file
File.open("lanes_template", 'w') { |file|
	file.puts(lanes)
}

# remove config file, it's trash
File.delete("configs_data.json") if File.exist?("configs_data.json")
