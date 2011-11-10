module LinkedRecordNotification
  def self.included(base)
    base.class_exec {
      before_destroy :notify_destroy
      before_update :save_old_values
      after_update :notify_update
      after_create :notify_create
    }
  end
  
  def save_old_values
    ps = self.class.find(self.id)
    @oldvalues = ps.get_value_hash
    return true
  end
  
  def notify_destroy
    unless self.organization.nil?
      self.organization.notify_related_record_change(:deleted, self)
    end
  end
  
  def notify_create
    unless self.organization.nil?
      self.organization.notify_related_record_change(:created, self)
    end
  end

  def notify_update
    unless self.organization.nil?
      self.organization.notify_related_record_change(:updated, self, @oldvalues)
    end
  end
  
end
