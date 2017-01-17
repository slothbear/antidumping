require "open-uri"

base = "http://enforcement.trade.gov/sas/programs/diffpriceprograms/"
files = %w{
  me-home-market-sas.txt
}

files.each do |web_file|
  open("#{base}#{web_file}") do |file|
    output_file = File.basename(web_file, '-sas.txt') + ".sas"
    File.write(output_file, file.read)
  end
end
