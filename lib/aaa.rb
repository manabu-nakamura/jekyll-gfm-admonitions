module Jekyll
  module Converters
    class Markdown
      class RedcarpetParser
        alias :old_convert :convert
        def convert(content)
          content.gsub!(/--(\w+)--/, "<s>\\1</s>")
          old_convert(content)
        end
      end
    end
  end
end