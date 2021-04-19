require 'match'
require 'fileutils'
require 'fastlane_core/ui/ui'

module Touchlane
  class LocalStorage < Match::Storage::Interface
    attr_accessor :signing_identities_path

    def self.configure(params)
      return self.new(
        # we can't pass signing_identities_path since params is hardcoded in match/runner.rb
        signing_identities_path: params[:git_url]
      )
    end

    def initialize(signing_identities_path: nil)
      self.signing_identities_path = signing_identities_path
    end

    def prefixed_working_directory
      return working_directory
    end

    def download
      # Check if we already have a functional working_directory
      return if @working_directory

      # No existing working directory, creating a new one now
      self.working_directory = Dir.mktmpdir

      Dir.mkdir(self.signing_identities_path) unless File.exists?(self.signing_identities_path)

      FileUtils.cp_r("#{self.signing_identities_path}/.", self.working_directory)
    end

    def human_readable_description
      "Local folder [#{self.signing_identities_path}]"
    end

    def upload_files(files_to_upload: [], custom_message: nil)
      # `files_to_upload` is an array of files that need to be moved to signing identities dir
      # Those doesn't mean they're new, it might just be they're changed
      # Either way, we'll upload them using the same technique

      files_to_upload.each do |current_file|
        # Go from
        #   "/var/folders/px/bz2kts9n69g8crgv4jpjh6b40000gn/T/d20181026-96528-1av4gge/profiles/development/Development_me.mobileprovision"
        # to
        #   "profiles/development/Development_me.mobileprovision"
        #

        # We also have to remove the trailing `/` as Google Cloud doesn't handle it nicely
        target_path = current_file.gsub(self.working_directory + "/", "")
        absolute_target_path = File.join(self.signing_identities_path, target_path)

        FileUtils.mkdir_p(File.dirname(absolute_target_path))

        FileUtils.cp_r(current_file, absolute_target_path, remove_destination: true)
      end
    end

    def delete_files(files_to_delete: [], custom_message: nil)
      files_to_delete.each do |file_name|
        target_path = file_name.gsub(self.working_directory + "/", "")
        File.delete(File.join(self.signing_identities_path, target_path))
      end
    end

    def skip_docs
      false
    end

    def list_files(file_name: "", file_ext: "")
      Dir[File.join(working_directory, "**", file_name, "*.#{file_ext}")]
    end

    def generate_matchfile_content
      path = Fastlane::UI.input("Path to the signing identities folder: ")

      return "git_url(\"#{path}\")"
    end

  end
end
