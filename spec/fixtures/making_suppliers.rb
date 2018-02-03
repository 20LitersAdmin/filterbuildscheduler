# creating suppliers from parts

parts = Part.all.where('length(supplier) > 0')

parts.each do |p|
  s = Supplier.find_or_create_by(name: a)
  
end
