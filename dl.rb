require "open-uri"

base = "https://access.trade.gov/resources/sas/programs/diffpriceprograms/"
files = %w{
  me-comparison-market-sas.txt
  me-margin-calculation-sas.txt
  me-macros-sas.txt
  nme-margin-calculation-sas.txt
  common-macros-sas.txt
}

files.each do |web_file|
  URI.open("#{base}#{web_file}") do |file|
    output_file = File.basename(web_file, '-sas.txt') + ".sas"
    File.write(output_file, file.read)
  end
end
