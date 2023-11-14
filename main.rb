require "google_drive"

session = GoogleDrive::Session.from_config("config.json")
ws = session.spreadsheet_by_key("1HndlZySAJ2M1mq9YS4H3pALq7mi3VXSIiR_ELgFJ7tI").worksheets[0]


class Table
  include Enumerable

  attr_accessor :ws

  def initialize(ws)
    @ws = ws

    define_column_methods()
  end

  def nice_print
    @ws.rows.each do |row|
      p row
    end
  end

  def row(i)
    @ws.rows[i]
  end

  def each
    @ws.rows.each do |row|
      row.each do |cell|
        yield cell
      end
    end
  end

  def [](column_header)
    header_index = @ws.rows[0].index(column_header)

    if header_index.nil?
      puts "No such header."
      return
    end

    col = []
    @ws.rows.each_with_index do |row, idx|
      col.append(row[header_index].to_i) unless idx == 0
    end
    col
  end

  def []=(column_header, index, val)
    p "USOOOO"
    header_index = @ws.rows[0].index(column_header)

    if header_index.nil?
      puts "No such header."
      return
    end
    @ws[index+1, header_index+1] = val
    @ws.save
    @ws.reload
  end

  private

  def define_column_methods()
    @ws.rows[0].each do |header|
      sym = header.gsub(' ', '_').downcase.to_sym
      self.class.send(:attr_accessor, sym)
      self.send("#{sym}=", self[header])
    end

  end

end

class Array
  def avg
    self.sum(0.0) / self.size
  end
end

table = Table.new(ws)

# p table["Druga kolona"]
# p "pre " + table["Druga kolona"][1]
# #table.[]=("Druga kolona", 1, 100)
# table["Druga kolona"][1] = 100
# p "posle " + table["Druga kolona"][1]
# p table["Druga kolona"]
p "prva kolona  " + table.prva_kolona.to_s
p "suma  " + table.prva_kolona.sum.to_s
p "avg  " + table.prva_kolona.avg.to_s

#table.nice_print
