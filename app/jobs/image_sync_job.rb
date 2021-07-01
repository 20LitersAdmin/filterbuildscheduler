# frozen_string_literal: true

class ImageSyncJob < ApplicationJob
  queue_as :image_sync

  def perform(*_args)
    # take all images from UID folder and attach them to an Item
    Dir['app/assets/images/uids/*'].each do |filename|
      uid = filename[/[A-Z][0-9]{3}/]
      extracted_type = filename[/[a-z]{3}$/]
      type = extracted_type == 'jpg' ? 'jpeg' : 'png'
      klass = uid[0]
      strid = uid[1..3].to_i

      object =
        case klass
        when 'C'
          Component
        when 'P'
          Part
        when 'M'
          Material
        end

      record = object.where(id: strid).first

      next unless record.present?

      record.image.attach(
        io: File.open(filename),
        filename: File.basename(filename),
        content_type: "image/#{type}"
      )
    end

    # create display_image attachments from Technology.img_url
    Technology.all.each do |tech|
      next if tech.img_url.nil?

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

    # create image attachments from Location.photo_url
    Location.all.each do |loc|
      next if loc.photo_url.nil?

      url = URI.parse(loc.photo_url)
      file = URI.parse(loc.photo_url).open
      filename = File.basename(url.path)
      extracted_type = filename[/\.[a-z]*/]
      extracted_type[0] = '' # remove the .
      type = extracted_type == 'jpg' ? 'jpeg' : extracted_type
      loc.image.attach(
        io: file,
        filename: filename,
        content_type: "image/#{type}"
      )
    end
  end
end

# Never trigger an analyzer when calling methods on ActiveStorage
ActiveStorage::Blob::Analyzable.module_eval do
  def analyze_later; end

  def analyzed?
    true
  end
end
