Rails.autoloaders.each do |autoloader|
  autoloader.ignore(Rails.root.join('app/models/brcobranca'))
end