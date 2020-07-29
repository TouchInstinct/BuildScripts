class String
    def with_wrapped_whitespace
        self.gsub(/\s+/, '\ ')
    end
    
    def filter_allowed_symbol_into_path
        self.gsub!(/[^0-9A-Za-z \-+.\/]/, '')
    end
  
    def true?
        self.to_s.downcase == "true"
    end
    
    def nilOrEmpty?
        self.nil? or self.empty?
    end
end
