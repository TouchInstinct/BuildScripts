require 'erb'

module Managers
  class TemplateManager

    include ERB::Util

    attr_accessor :items

    def initialize(items)
      @items = items
    end

    def render(template)
      ERB.new(template).result(binding)
    end

  end
end
