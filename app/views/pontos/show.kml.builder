xml.instruct!
xml.kml("xmlns" => "http://www.opengis.net/kml/2.2", "xmlns:gx" => "http://www.google.com/kml/ext/2.2", "xmlns:kml" => "http://www.opengis.net/kml/2.2", "xmlns:atom" => "http://www.w3.org/2005/Atom") do
  xml.Document do
    @ponto.conexoes.where.not(latitude: nil, longitude: nil).each do |conexao|
      xml.Placemark do
        xml.name conexao.pessoa.nome
        xml.Point do
          xml.coordinates "#{conexao.longitude}, #{conexao.latitude}"
        end
      end
    end
  end
end