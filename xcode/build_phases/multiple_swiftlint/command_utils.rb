class CommandUtils
    def self.make_command(command)
        command = command.to_s
        return `#{command}`
    end
end