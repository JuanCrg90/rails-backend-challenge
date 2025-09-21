namespace :availability do
  desc "Sync availabilities from Calendly for a given provider_id (or all providers)"
  task sync: :environment do
    puts "Syncing availabilities for ALL providers..."
    Provider.find_each do |provider|
      count = AvailabilitySync.new.call(provider_id: provider.id)
      puts "Synced #{count} availability slots for provider #{provider.id}"
    end
  end
end
