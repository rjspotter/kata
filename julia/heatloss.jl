cavity_u = 1 / 12.5 # 11(insulation) 1(cladding) 0.5(drywall)
stud_u = 1 / 5 # 3.5(stud) 1(cladding) 0.5(drywall)
window_u = 1 / 3.35
door_u = 1 / 5
bay_u = 1 / 20 # 19.25(5.5in@3.5r insulation) 0.5(drywall)

spacing = 16
stud = 1.5
header = 13.5 # 12(above) 1.5(below)
plate = 4.5 # total plate inches 2 top 1 bottom

function wall_assembly(width, height=96, windows=[], doors=[])
  total_area = width * height
  window_area = 0

  stud_count = ceil(width / spacing)
  stud_height = height - plate
  stud_area = (stud * stud_height * stud_count) / total_area

  for w in windows
    window_area += foldl(*, w)
    stud_area += (header * w[1]) + (2 * stud * stud_height)
  end

  for d in doors
    door_area += foldl(*, d)
    stud_area += (header * d[1]) + (2 * stud * stud_height)
  end

  cavity_area = ((total_area - stud_area) - window_area) - door_area

  stud_area_percent = stud_area / total_area
  cavity_area_percent = cavity_area / total_area
  window_area_percent = window_area / total_area
  door_area_percent = door_area / total_area

  (stud_u * stud_area_percent) + (cavity_u * cavity_area_percent) + (window_u * window_area_percent) + (door_u * door_area_percent) 
end

function ceiling_assembly(width, height)
  total_area = width * height

  stud_count = ceil(width / spacing)
  stud_height = height - plate
  stud_area = (stud * stud_height * stud_count) / total_area

  cavity_area = total_area - stud_area

  stud_area_percent = stud_area / total_area
  cavity_area_percent = cavity_area / total_area

  (stud_u * stud_area_percent) + (bay_u * cavity_area_percent)
end


radiant_loss = 0

# Dining Room
radiant_loss += wall_assembly(173, 96, [[53, 62]])

# Kitchen
radiant_loss += wall_assembly(131, 96, [[33, 39]])

# Laundry Room
radiant_loss += wall_assembly(58, 96, [], [[32, 80]])
radiant_loss += wall_assembly(58, 96)
radiant_loss += wall_assembly(126, 96, [[53, 51]])

# Den
radiant_loss += wall_assembly(286, 96, [[78, 62]], [[78, 80]])

# Parlor
radiant_loss += wall_assembly(199, 96, [[87, 75]])

# Foyer
radiant_loss += wall_assembly(80, 96, [], [[36, 80]])

# Em Office
radiant_loss += wall_assembly(120, 96, [[68.5, 73]])

# Bathroom
radiant_loss += wall_assembly(95, 96, [[28, 38]])

# Master Bedroom
radiant_loss += wall_assembly(144, 96, [[75, 80]])

# Master Bathroom
radiant_loss += wall_assembly(78, 123, [[21, 25]])
radiant_loss += wall_assembly(122, 123, [[33, 76]])

# Closet
radiant_loss += wall_assembly(60, 96)
radiant_loss += wall_assembly(51, 103, [[21, 25]])
radiant_loss += wall_assembly(124, 103, [[24, 28]])

# My Office
radiant_loss += wall_assembly(120, 96, [[59, 73.5]])
radiant_loss += wall_assembly(165, 96, [[41.5, 49.5]])
