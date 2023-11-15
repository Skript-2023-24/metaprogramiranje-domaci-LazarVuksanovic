require "google_drive"
require_relative 'Table.rb'

session = GoogleDrive::Session.from_config("config.json")

ws = session.spreadsheet_by_key("1HndlZySAJ2M1mq9YS4H3pALq7mi3VXSIiR_ELgFJ7tI").worksheets[0]
ws1 = session.spreadsheet_by_key("1HndlZySAJ2M1mq9YS4H3pALq7mi3VXSIiR_ELgFJ7tI").worksheets[1]

table = Table.new(ws)
table2 = Table.new(ws1)


table3 = table + table2
table4 = table - table2

puts "Rezultat sabiranja:\n#{table3.rows}\n\n\n"
puts "Kolona 'Ime prezime' u prvoj tabeli\n#{table["Ime prezime"]}\n\n\n"
puts "37 element u koloni iznad #{table["Ime prezime"][37]}"

table["Ime prezime"][37] = "Tanasko Rajic"
puts "Nakon promene vrednosti #{table["Ime prezime"][37]}\n\n\n"

puts "Suma kolone: #{table.ocena.sum}"
puts "Avg kolone:  #{table.ocena.avg}"
puts "Prikaz trazenog reda: #{table.index.rn_1021}\n\n\n"

map = table.ime_prezime.map do |cell|
  "Student #{cell}"
end
puts "Map:\n#{map}\n\n\n"

select = table.ocena.select do |cell|
  cell > 5
end
puts "Select: #{select}"

reduce = table.bodovi.reduce(0) do |sum, cell|
  sum += 1 if cell.to_f > 5
  sum
end
puts "Reduce: #{reduce}\n\n"
