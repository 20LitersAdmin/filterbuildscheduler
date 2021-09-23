# frozen_string_literal: true

class ImageSyncJob < ApplicationJob
  queue_as :image_sync

  def perform(*_args)
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting ImageSyncJob ========================='

    puts 'taking all images from UID folder and attaching them to an Item'
    Dir['app/assets/images/uids/*'].each do |filename|
      uid = filename[/[A-Z][0-9]{3}/]
      extracted_type = filename[/[a-z]{3}$/]
      type = extracted_type == 'jpg' ? 'jpeg' : 'png'

      record = uid.objectify_uid

      next if record.nil? || record.image.attached?

      record.image.attach(
        io: File.open(filename),
        filename: File.basename(filename),
        content_type: "image/#{type}"
      )
    end
    puts 'Done traversing the UID folder'

    # create display_image attachments from Technology.img_url
    Technology.all.each do |tech|
      next if tech.img_url.nil? || tech.display_image.attached?

      url = URI.parse(tech.img_url)
      file = URI.parse(tech.img_url).open
      filename = File.basename(url.path)
      extracted_type = filename[/\.[a-z]*/]
      extracted_type[0] = '' # remove the .
      type = extracted_type == 'jpg' ? 'jpeg' : extracted_type

      tech.display_image.attach(
        io: file,
        filename: filename,
        content_type: "image/#{type}"
      )
    end

    puts 'Done traversing Technologies'

    # create image attachments from Location.photo_url
    Location.all.each do |loc|
      next if loc.photo_url.blank? || loc.image.attached?

      url = URI.parse(loc.photo_url)

      # If the file can't be found or opened, move on
      begin
        file = URI.parse(loc.photo_url).open
      rescue OpenURI::HTTPError
        puts "Failed: #{loc.id}: #{loc.name}"
        next
      end

      filename = File.basename(url.path)
      extracted_type = filename[/\.[a-z]*/]

      # if the URL doesn't point to an actual file, move on
      next if extracted_type.nil?

      extracted_type[0] = '' # remove the .
      type = extracted_type == 'jpg' ? 'jpeg' : extracted_type
      loc.image.attach(
        io: file,
        filename: filename,
        content_type: "image/#{type}"
      )
    end

    puts 'Done traversing Locations'

    puts '========================= FINISHED ImageSyncJob ========================='

    ActiveRecord::Base.logger.level = 0
  end
end
