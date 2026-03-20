# frozen_string_literal: true

require 'spec_helper'

DocStub = Struct.new(:content, :path)

RSpec.describe JekyllGFMAdmonitions::GFMAdmonitionConverter do
  let(:markdown_converter) { double('Jekyll::Converters::Markdown') }

  subject(:converter) do
    obj = described_class.allocate
    obj.instance_variable_set(:@markdown, markdown_converter)
    obj
  end

  # Make markdown_converter return a simple <p> wrapper by default
  before do
    allow(markdown_converter).to receive(:convert) do |text|
      "<p>#{text.strip}</p>\n"
    end
  end

  # -----------------------------------------------------------------------
  # process_doc helpers
  # -----------------------------------------------------------------------

  def doc_with(content)
    DocStub.new(content.dup, 'test.md')
  end

  # -----------------------------------------------------------------------
  # Frozen string guard
  # -----------------------------------------------------------------------

  describe '#process_doc' do
    it 'does not raise when content is frozen' do
      doc = doc_with("> [!NOTE]\n> hello\n".freeze)
      expect { converter.send(:process_doc, doc) }.not_to raise_error
    end

    it 'returns early on empty content' do
      doc = doc_with('')
      converter.send(:process_doc, doc)
      expect(doc.content).to eq('')
    end

    it 'leaves non-admonition content unchanged' do
      doc = doc_with("# Hello\n\nJust some text.\n")
      converter.send(:process_doc, doc)
      expect(doc.content).to eq("# Hello\n\nJust some text.\n")
    end

    # -----------------------------------------------------------------------
    # All 5 admonition types
    # -----------------------------------------------------------------------

    %w[NOTE TIP WARNING IMPORTANT CAUTION].each do |type|
      it "renders #{type} admonitions" do
        doc = doc_with("> [!#{type}]\n> body\n")
        converter.send(:process_doc, doc)
        expect(doc.content).to include("markdown-alert-#{type.downcase}")
      end
    end

    # -----------------------------------------------------------------------
    # Code blocks are restored exactly
    # -----------------------------------------------------------------------

    it 'leaves admonitions inside code blocks untouched' do
      code = "```\n> [!NOTE]\n> secret\n```"
      doc = doc_with(code)
      converter.send(:process_doc, doc)
      expect(doc.content).to include('> [!NOTE]')
    end

    it 'restores code block content exactly' do
      original = "```ruby\nputs 'hello'\n```\n"
      doc = doc_with(original)
      converter.send(:process_doc, doc)
      expect(doc.content).to eq(original)
    end
  end

  # -----------------------------------------------------------------------
  # convert_admonitions
  # -----------------------------------------------------------------------

  describe '#convert_admonitions' do
    it 'uses a custom title when provided' do
      doc = doc_with("> [!NOTE] My Custom Title\n> body\n")
      converter.send(:convert_admonitions, doc)
      expect(doc.content).to include('My Custom Title')
    end

    it 'falls back to capitalised type when title is blank' do
      doc = doc_with("> [!NOTE]\n> body\n")
      converter.send(:convert_admonitions, doc)
      expect(doc.content).to include('Note')
    end

    it 'preserves indentation for admonitions inside list items' do
      doc = doc_with("1. item\n\n   > [!NOTE]\n   > indented body\n")
      converter.send(:convert_admonitions, doc)
      # The replacement div must start at the same column as the blockquote
      expect(doc.content).to match(/^   <div/)
    end

    it 'captures multi-line body correctly' do
      doc = doc_with("> [!TIP]\n> line one\n> line two\n")
      converter.send(:convert_admonitions, doc)
      expect(doc.content).to include('line one')
      expect(doc.content).to include('line two')
    end
  end

  # -----------------------------------------------------------------------
  # admonition_html — .md link rewriting
  # -----------------------------------------------------------------------

  describe '#admonition_html' do
    let(:icon) { '' }

    before do
      allow(markdown_converter).to receive(:convert) do |text|
        # Simulate a rendered link
        text
      end
    end

    it 'rewrites relative .md links to .html' do
      allow(markdown_converter).to receive(:convert)
        .with('see [page](other.md)')
        .and_return('<p>see <a href="other.md">page</a></p>')

      html = converter.send(:admonition_html, 'note', 'Note', 'see [page](other.md)', icon)
      expect(html).to include('href="other.html"')
      expect(html).not_to include('href="other.md"')
    end

    it 'preserves anchor fragments when rewriting .md links' do
      allow(markdown_converter).to receive(:convert).and_return(
        '<p><a href="other.md#section">link</a></p>'
      )

      html = converter.send(:admonition_html, 'note', 'Note', 'text', icon)
      expect(html).to include('href="other.html#section"')
    end

    it 'does not rewrite external https:// .md URLs' do
      allow(markdown_converter).to receive(:convert).and_return(
        '<p><a href="https://example.com/page.md">ext</a></p>'
      )

      html = converter.send(:admonition_html, 'note', 'Note', 'text', icon)
      expect(html).to include('href="https://example.com/page.md"')
    end
  end
end
