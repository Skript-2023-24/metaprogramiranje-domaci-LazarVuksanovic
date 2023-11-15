require "google_drive"

class Column
  include Enumerable

  attr_accessor :val

  def initialize(val, name, table)
    @val = val
    @name = name
    @table = table
  end

  def [](i)
    @val[i]
  end

  def []=(i, val)
    @val[i] = val
    @table.[]=(@name, i, val)
    @val[i]
  end

  def to_s
    @val.to_s
  end
end

class Table
  include Enumerable

  attr_accessor :ws
  attr_accessor :selected_col
  attr_accessor :offset_i
  attr_accessor :offset_j
  attr_accessor :null_rows

  def initialize(ws)
    @ws = ws
    @null_rows = []

    setup_table()
  end

  def setup_table()

    set_offsets()
    define_column_methods()

    @ws.rows.each_with_index do |ws_row, i|
      next if i < offset_i
      total_row = false
      null_row = true
      ws_row.each_with_index do |cell, j|
        next if j < offset_j
        null_row = false if cell != ""
        total_row = true if cell == "total" || cell == "subtotal"
      end
      @null_rows << i if null_row || total_row
    end
  end

  def set_offsets()
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
    @ws.rows.each_with_index do |row, i|
      next if i < offset_i || @null_rows.include?(i)
      print_row = []
      row.each_with_index do |cell, j|
        print_row << cell.to_s unless j < offset_j
      end
      p print_row
    end
  end

  def row(i)
    @ws.rows[i + offset_i][offset_j..-1]
  end

  def rows
    r = []
    (1..@ws.rows.size-offset_i-1).each do |i|
      r << self.row(i) unless @null_rows.include?(i + offset_i)
    end
    r
  end

  def [](column_header)
    header_index = @ws.rows[offset_i].index(column_header)

    if header_index.nil?
      puts "No such header."
      return
    end

    col = []
    @ws.rows.each_with_index do |row, idx|
      next if @null_rows.include?(idx) || idx <= offset_i
      if row[header_index].match(/[1-9][0-9]*|0/).to_s.size == row[header_index].size
        col.append(row[header_index].to_i) unless idx == 0
      else
        col.append(row[header_index]) unless idx == 0
      end
    end
    Column.new(col, column_header, self)
  end

  def []=(column_header, index, val)
    header_index = @ws.rows[offset_i].index(column_header)
    if header_index.nil?
      puts "No such header."
      return
    end
    index = ignore_empty_rows(index)
    # dodajemo 1 na indexe zato sto u ws indexiranje krece od 1
    @ws[offset_i + index+1, offset_j + header_index] = val
    save()
  end

  def each
    @ws.rows.each_with_index do |row, i|
      next if row.empty? || i < offset_i
      row.each_with_index do |cell, j|
        yield cell unless j < offset_j
      end
    end
  end

  def map(&block)
    @selected_col.val.map(&block)
  end

  def select(&block)
    @selected_col.val.select(&block)
  end

  def reduce(initial = nil, &block)
    if initial.nil?
      @selected_col.val.reduce(&block)
    else
      @selected_col.val.reduce(initial, &block)
    end
  end

  def sum
    @selected_col.val.sum
  end

  def avg
    @selected_col.val.sum(0.0) / @selected_col.val.size
  end

  def to_s
    f = []
    @ws.rows.each_with_index do |row, i|
      next if i < offset_i
      print_row = []
      row.each_with_index do |cell, j|
        print_row << cell unless j < offset_j
      end
      f << print_row
    end
    f.to_s
  end

  def save
    @ws.save
    @ws.reload
  end

  def +(table2)
    return unless self.row(0) == table2.row(0)

    new_ws = @ws.spreadsheet.add_worksheet("#{self.ws.title} + #{table2.ws.title}")
    result_rows = self.rows | table2.rows
    result_rows.each_with_index do |row, row_index|
      row.each_with_index do |cell, col_index|
        new_ws[row_index + 1, col_index + 1] = cell
      end
    end

    result = Table.new(new_ws)
    result.save
    result
  end

  def -(table2)

    return unless self.row(0) == table2.row(0)

    new_ws = @ws.spreadsheet.add_worksheet("#{self.ws.title} - #{table2.ws.title}")

    result_rows = self.rows - table2.rows
    result_rows.each_with_index do |row, row_index|
      row.each_with_index do |cell, col_index|
        new_ws[row_index + 1, col_index + 1] = cell
      end
    end
    result = Table.new(new_ws)
    result.save
    result
  end

  private

  def define_column_methods()
    @ws.rows[offset_i].each do |header|
      sym = header.gsub(' ', '_').downcase.to_sym
      self.class.send(:define_method, sym) do
        @selected_col = self[header]
        self
      end
    end
  end

  def method_missing(key, *args)
    @selected_col.val.each_with_index do |e, i|
      if e == key.to_s.upcase.gsub('_', ' ')
        return @ws.rows[ignore_empty_rows(i + offset_i)][offset_j..-1]
      end
    end
    nil
  end

  def ignore_empty_rows(index)
    # dodajemo 1 na indexe zbog reda hedera
    index += 1
    if !@null_rows.empty?
      null_rows.each do |null_row|
        index += 1 if index >= null_row
      end
    end
    index
  end
end

session = GoogleDrive::Session.from_config("config.json")

ws = session.spreadsheet_by_key("1HndlZySAJ2M1mq9YS4H3pALq7mi3VXSIiR_ELgFJ7tI").worksheets[0]
ws1 = session.spreadsheet_by_key("1HndlZySAJ2M1mq9YS4H3pALq7mi3VXSIiR_ELgFJ7tI").worksheets[1]

table = Table.new(ws)
table2 = Table.new(ws1)

# table3 = table + table2 #️✔
# table3 = table - table2 #️✔


# p table.rows #️✔
# puts table["Ime prezime"] #️✔
# p table["Ime prezime"][144] #️✔
# table.[]=("Redni broj", 144, 100000) #️✔
# table["Redni broj"][1]= 10000 #️✔
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

# reduce = table.redni_broj.reduce(0) do |sum, cell| #️✔
#   sum + cell
# end
# p reduce
