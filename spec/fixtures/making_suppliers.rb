# creating suppliers from parts

parts = Part.all.where('length(supplier_name) > 0')

parts.each do |p|
  Supplier.find_or_create_by(name: p.supplier_name)
end

materials = Material.all.where('length(supplier_name) > 0')

materials.each do |m|
  Material.find_or_create_by(name: m.supplier_name)
end

