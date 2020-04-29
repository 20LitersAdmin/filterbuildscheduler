# frozen_string_literal: true

# CleanupService.clean_events_and_users!
# CleanupService.clean_inventories!

class CleanupService
  def self.techs
    owner = 'Village Water Filters'

    Technology.all.where(owner: owner)
  end

  def self.tech_ids
    techs.map(&:id)
  end

  def self.clean_events_and_users!
    ActiveRecord::Base.logger.silence do
      # soft_delete_builds
      # soft_delete_orphans
      # reset_non_builders
      # reset_builders
      # puts 'Done!'
      puts 'Yeah, you don\'t really wanna do that.'
    end
  end

  def self.clean_inventories!
    ActiveRecord::Base.logger.silence do
      soft_delete_counts
      soft_delete_components
      soft_delete_materials
      soft_delete_parts
      soft_delete_technologies
      puts 'Done!'
    end
  end

  def self.soft_delete_builds
    events = Event.all.where(technology_id: tech_ids)

    puts "Soft-deleting #{events.size} builds"
    # also destroys child registrations
    events.find_each(&:destroy!)
  end

  def self.reset_builders
    builders = User.builders
    size = builders.size

    puts "Resetting #{size} builders"

    builders.update_all(
      reset_password_sent_at: nil,
      remember_created_at: nil,
      sign_in_count: 0,
      current_sign_in_at: nil,
      last_sign_in_at: nil,
      current_sign_in_ip: nil,
      last_sign_in_ip: nil,
      signed_waiver_on: nil
    )

    puts 'Resetting passwords, this will take a while...'

    idx = 0
    builders.find_each do |builder|
      reset_password(builder)
      idx += 1
      print "==> completed: #{idx}/#{size}\r"
      $stdout.flush
    end

    puts '==> all passwords for builders have been reset.'
  end

  def self.reset_password(builder)
    new_password = Devise.friendly_token(50)
    builder.reset_password(new_password, new_password)
  end

  def self.reset_non_builders
    non_builders = User.non_builders

    puts "Resetting #{non_builders.size} non-builders"

    non_builders.update_all(
      reset_password_sent_at: nil,
      remember_created_at: nil,
      sign_in_count: 0,
      current_sign_in_at: nil,
      last_sign_in_at: nil,
      current_sign_in_ip: nil,
      last_sign_in_ip: nil
    )
  end

  def self.soft_delete_orphans
    # Users with no registrations or special permissions
    orphans = User.builders.without_registrations

    puts "Soft-deleting #{orphans.size} orphans"

    orphans.find_each(&:destroy!)
  end

  def self.soft_delete_counts
    # first, pull every count related to these technologies
    count_ids = []
    Count.all.map { |c| count_ids << c.id if (c.technologies.map(&:id) - tech_ids).empty? }

    # and delete them
    counts = Count.where(id: count_ids)
    size = counts.size

    puts "Soft-deleting #{size} inventory counts"

    idx = 0
    counts.find_each do |count|
      count.destroy!
      idx += 1
      print "==> completed: #{idx}/#{size}\r"
      $stdout.flush
    end

    puts '===> finished soft-deleting counts'
  end

  def self.soft_delete_components
    comp_ids = []
    Component.all.map { |c| comp_ids << c.id if (c.technologies.map(&:id) - tech_ids).empty? }

    comps = Component.where(id: comp_ids)

    puts "Soft-deleting #{comps.size} components"

    # deleting the component also deletes the extrapolate_component_ records, but not the actual items.
    comps.find_each(&:destroy!)
  end

  def self.soft_delete_materials
    mat_ids = []
    Material.all.map { |m| mat_ids << m.id if (m.technologies.map(&:id) - tech_ids).empty? }

    mats = Material.where(id: mat_ids)

    puts "Soft-deleting #{mats.size} materials"

    mats.find_each(&:destroy!)
  end

  def self.soft_delete_parts
    part_ids = []
    Part.all.map { |i| part_ids << i.id if (i.technologies.map(&:id) - tech_ids).empty? }

    parts = Part.where(id: part_ids)

    puts "Soft-deleting #{parts.size} components"

    # deleting the part also deletes the extrapolate_ records, but not the actual items.
    parts.find_each(&:destroy!)
  end

  def self.soft_delete_technologies
    puts "Soft-deleting #{techs.size} technologies"

    techs.find_each(&:destroy!)
  end
end
