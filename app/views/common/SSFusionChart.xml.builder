caption ||= ''
subcaption ||= ''
suffix ||= ''
decimal_precision ||= 0
show_values ||= 0
y_axis_min_value ||= 0

xml = Builder::XmlMarkup.new
xml.instruct!

xml.graph :caption => caption, :subcaption => subcaption, :numberSuffix => suffix, :showValues => show_values, :formatNumberScale => 0, :yAxisMinValue => (y_axis_min_value/100)*100, :decimalPrecision => decimal_precision, :showBorder => 1, :rotateNames => 1, :showNames => 1, :pieSliceDepth => 20, :pieYScale => 90, :numVDivLines => 22, :divLineAlpha => 80, :showAlternateHGridColor => 1, :AlternateHGridAlpha => 30, :AlternateHGridColor => 'CCCCCC' do

  data.each do |l|
    xml.set :name => l[:name], :value => l[:value]
  end

end

