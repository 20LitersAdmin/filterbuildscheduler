module CleanupCrew

  def clean_up!

    Registration.with_deleted.each do |r|
      r.really_destroy!
    end

    User.with_deleted.each do |u|
      u.really_destroy!
    end

    Event.with_deleted.each do |e|
      e.really_destroy!
    end

    Location.with_deleted.each do |l|
      l.really_destroy!
    end

    Technology.with_deleted.each do |t|
      t.really_destroy!
    end

  end
end