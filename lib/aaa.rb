# frozen_string_literal: true

module JekyllGFMAdmonitions2
  class GFMAdmonitionConverter2 < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)
      process_posts(site)
      process_pages(site)
    end

    def process_posts(site)
      site.posts.docs.each do |doc|
        process_doc_content(doc)
      end
    end

    def process_pages(site)
      site.pages.each do |page|
        process_doc_content(page)
      end
    end

    def process_doc_content(doc)
      unless doc.content.empty?
        doc.content = doc.content.dup unless doc.content.frozen?
        doc.content.gsub!(/--(\w+)--/) do
          "<s>$1</s>"
        end
      end
    end
  end
end