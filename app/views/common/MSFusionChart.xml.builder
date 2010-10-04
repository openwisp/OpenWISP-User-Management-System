caption ||= ''
subcaption ||= ''
suffix ||= ''
decimal_precision ||= 0
show_values ||= 0
format_number_scale ||= 0
format_number ||= 1

xml = Builder::XmlMarkup.new :indent => 0
xml.instruct!

xml.graph :caption => caption, :subcaption => subcaption, :numberSuffix => suffix, :showValues => show_values, :decimalPrecision => decimal_precision, :formatNumber => format_number, :formatNumberScale => format_number_scale, :showBorder => 1, :divLineColor => 'CCCCCC', :divLineAlpha => 80, :numVDivLines => 22, :showAlternateHGridColor => 1, :AlternateHGridAlpha => 30, :AlternateHGridColor => 'CCCCCC', :rotateNames => 1 do
  xml.categories do
   categories.each do |c|
     xml.category :name => c
   end
  end
  
  series.each do |s|
    xml.dataset :seriesname => s[:name], :color => s[:color] do
      s[:data].each do |d|
        xml.set :value => d
      end
    end
  end
end

