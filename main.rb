require "google_drive"

session = GoogleDrive::Session.from_config("config.json")
ws = session.spreadsheet_by_key("1HndlZySAJ2M1mq9YS4H3pALq7mi3VXSIiR_ELgFJ7tI").worksheets[0]

class Table
  include Enumerable

  attr_accessor :ws
  attr_accessor :selected_col
  attr_accessor :rows
  attr_accessor :offset_i
  attr_accessor :offset_j
  attr_accessor :null_rows

  def initialize(ws)
    @ws = ws
    @rows = []
    @null_rows = []
    offsets()
    set_rows()
    define_column_methods()
  end

  def set_rows()
    @ws.rows.each_with_index do |ws_row, i|
      row = []
      in_table = false
      ws_row.each_with_index do |cell, j|
        if (cell != "" && !in_table) || in_table
          row << cell #Cell.new(i, j, cell)
          in_table = true
        end
      end
      @null_rows << i if row == []
      @rows << row
      in_table = false
    end
  end

  def offsets()
    @ws.rows.each_with_index do |row, i|
      row.each_with_index do |cell, j|
        next if cell == ""
        @offset_i = i
        @offset_j = j
        return
      end
    end

  end

  def nice_print
    @rows.each do |row|
      print_row = []
      #next if row.empty?

      row.each do |cell|
        print_row << cell.to_s
      end

      p print_row
    end
  end

  def row(i)
    @rows[i]
  end

  def [](column_header)
    header_index = @rows[0].index(column_header)

    if header_index.nil?
      puts "No such header."
      return
    end

    col = []
    @rows.each_with_index do |row, idx|
      next if row.empty?
      if row[header_index].match(/[1-9][0-9]*|0/).to_s.size == row[header_index].size
        col.append(row[header_index].to_i) unless idx == 0
      else
        col.append(row[header_index]) unless idx == 0
      end
    end
    col
  end

  def []=(column_header, index, val)
    index = ignore_empty_rows(index)

    header_index = @rows[0].index(column_header)
    if header_index.nil?
      puts "No such header."
      return
    end

    # dodajemo 1 na indexe zato sto u ws indexiranje krece od 1
    @ws[offset_i + index+1, offset_j + header_index+1] = val
    @ws.save
    @ws.reload
  end

  def each
    @rows.each do |row|
      next if row.empty?
      row.each do |cell|
        yield cell
      end
    end
  end

  def map(&block)
    @selected_col.map(&block)
  end

  def select(&block)
    @selected_col.select(&block)
  end

  def reduce(initial = nil, &block)
    if initial.nil?
      @selected_col.reduce(&block)
    else
      @selected_col.reduce(initial, &block)
    end
  end

  def sum
    @selected_col.sum
  end

  def avg
    @selected_col.sum(0.0) / @selected_col.size
  end

  def to_s
    f = ""
    @rows.each do |row|
      print_row = []
      row.each do |cell|
        print_row << cell.to_s
      end
      f << print_row.to_s
    end
    f
  end

  private

  def define_column_methods()
    @rows[0].each do |header|
      sym = header.gsub(' ', '_').downcase.to_sym

      self.class.send(:define_method, sym) do
        @selected_col = self[header]
        self
      end
    end
  end

  def method_missing(key, *args)
    @selected_col.each_with_index do |e, i|
      if e == key.to_s.upcase.gsub('_', ' ')
        return @rows[ignore_empty_rows(i)]
      end
    end
    nil
  end

  def ignore_empty_rows(index)
    # dodajemo 1 na indexe zbog reda hedera
    index +=1
    if @null_rows
      null_rows.each do |null_row|
        index += 1 if index >= null_row
      end
    end
    index
  end

end

table = Table.new(ws)

# p table["Ime prezime"] #️✔
# p table["Ime prezime"][144] #️✔
# table.[]=("Redni broj", 144, 100000) #️✔
# table["Redni broj"][1]= 10000
# table.index; p table.selected_col #️✔

# p "suma  #{table.redni_broj.sum}" #️✔
# p "avg  #{table.redni_broj.avg}" #️✔
# p table.index.rn_1021 #️✔

# map = table.redni_broj.map do |cell| #️✔
#   cell += 10000
# end
# p map

# select = table.redni_broj.select do |cell| #️✔
#   cell.even?
# end
# p select

# reduce = table.redni_broj.reduce(0) do |sum, cell|
#   sum + cell
# end
# p reduce
