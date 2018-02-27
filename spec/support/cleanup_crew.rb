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

    Count.with_deleted.each do |c|
      c.really_destroy!
    end

    Inventory.with_deleted.each do |i|
      i.really_destroy!
    end

    Component.with_deleted.each do |c|
      c.really_destroy!
    end

    Part.with_deleted.each do |part|
      part.really_destroy!
    end

    Material.with_deleted.each do |m|
      m.really_destroy!
    end

    Supplier.with_deleted.each do |s|
      s.really_destroy!
    end

    ActiveRecord::Base.connection.tables.each do |t|
      ActiveRecord::Base.connection.reset_pk_sequence!(t)
    end
  end
end