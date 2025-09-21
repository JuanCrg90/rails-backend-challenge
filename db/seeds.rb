Provider.find_or_create_by!(id: 1) do |p|
  p.first_name = "sheldon"
  p.last_name  = "cooper"
  p.email      = "sheldon.cooper@test.com"
  p.location   = "Pasadena, California"
end

Provider.find_or_create_by!(id: 2) do |p|
  p.first_name = "leonard"
  p.last_name  = "hofstadter"
  p.email      = "leonard.hofstadter@test.com"
  p.location   = "Pasadena, California"
end

Provider.find_or_create_by!(id: 3) do |p|
  p.first_name = "rajesh"
  p.last_name  = "koothrappali"
  p.email      = "rajesh.koothrappali@test.com"
  p.location   = "Pasadena, California"
end

Client.find_or_create_by!(id: 1) do |c|
  c.first_name = "Jenna"
  c.last_name  = "Ortega"
  c.email      = "jenna.ortega@test.com"
  c.location   = "Los Angeles, California"
end

Appointment.find_or_create_by!(id: 1) do |a|
  a.provider_id = 1
  a.client_id   = 1
  a.starts_at  = "2025-09-22T11:00:00-05:00"
  a.ends_at    = "2025-09-22T11:30:00-05:00"
  a.status      = 0
end