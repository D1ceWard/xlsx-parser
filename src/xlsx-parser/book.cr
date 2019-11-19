require "zip"
require "xml"

module XlsxParser
  class Book
    getter zip : Zip::File
    getter sheets : Array(Sheet) = [] of Sheet
    getter shared_strings : Array(String)

    def initialize(io : IO)
      @zip = Zip::File.new(io)
      @shared_strings = [] of  String

      node = XML.parse(@zip["xl/sharedStrings.xml"].open(&.gets_to_end))
      node.xpath_nodes("//*[name()='si']/*[name()='t']").each do |t_node|
        @shared_strings << t_node.content
      end
    end

    def sheets
      workbook = XML.parse(@zip["xl/workbook.xml"].open(&.gets_to_end))
      sheets_nodes = workbook.xpath_nodes("//*[name()='sheet']")

      rels = XML.parse(@zip["xl/_rels/workbook.xml.rels"].open(&.gets_to_end))

      @sheets = sheets_nodes.map do |sheet|
        sheetfile = rels.xpath_string(
          "string(//*[name()='Relationship' and contains(@Id,'#{sheet["id"]}')]/@Target)"
        )
        Sheet.new(self, sheetfile)
      end
    end

    def close
      @zip.close
    end
  end
end