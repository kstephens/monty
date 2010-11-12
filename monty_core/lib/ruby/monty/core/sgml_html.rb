module Monty
  module Core
    module SgmlHtml

      # The SGML DOCTYPE: :xhtml_transitional, :xhtml_strict
      attr_accessor :sgml_doctype

      SGML_DOCTYPES = {
        :xhtml_transitional =>
        %Q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">}.freeze,
        :xhtml_strict => 
        %Q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">}.freeze,
      }

      def prepare_html_result result_dom
        # Get the XML DOM data as a String.
        result_dom = result_dom.root.to_s unless String === result_dom

        # Remove the html xmlns.
        result_dom.sub!(/^<html xmlns=[^>]+>/, '<html>')
        
        # Browsers cannot handle self-terminated block-oriented tags: <script .../> and <div .../>.
        result_dom.gsub!(%r{<((script|div)[^>]*?)/>}mi) { | x | '<' + $1 + '></' + $2 + '>'}
        
        # Unescaping SGML entities in block-oriented tags: <script> and <style> tags.
        result_dom.gsub!(%r{(<(script|style)[^>]*?>)(.+?)(</\2>)}mi) do | x |
          tag_start, content, tag_end = $1, $3, $4
          # STDERR.puts " =====> #{tag_start} #{content} #{tag_end}"
          SgmlEntity.decode!(content)
          tag_start << content << tag_end
        end

        result_dom
      end

      def prepend_sgml_doctype result_dom
        result_dom = result_dom.to_s unless String === result_dom

        # Add the appropriate SGML <!DOCTYPE ...> tag.
        result = (SGML_DOCTYPES[sgml_doctype] || sgml_doctype).to_s.dup << "\n"
        
        # Append the modified XML DOM data.
        result << result_dom
      end

      extend self
    end # module
  end # module
end # module


