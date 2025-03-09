module Jekyll
  module Converters
    class Markdown
      class KramdownParser
        alias :old_convert :convert
        def convert(content)
          unless content.empty?
            content = content.dup unless content.frozen?
            content.gsub!(/--(\w+)--/, "<s>\\1</s>")
          end
          old_convert(content)
        end
      end
    end
  end
end