module Common
  def Common::detect_changes(old, attr_hash)
    # NOTE: old may be either a model or a hash. all fields are referenced through object[]
    # go through each parameter in attr_hash and if present in object and value is different, add to results
    # result is a hash of key to hash{:old => X, :new => Y} or nil if no changes detected
    return nil if attr_hash.nil?
    changes = {}
    attr_hash.each do |key,newvalue|
      oldvalue = old[key]
      value_changed = false
      if oldvalue.nil?
        unless newvalue.nil? # if both are nil, no change
          value_changed = true unless newvalue.same_value?(oldvalue)
        end
      else
        value_changed = true unless oldvalue.same_value?(newvalue)
      end
      changes[key] = {:old => oldvalue, :new => newvalue} if value_changed
    end
    return changes
  end

  def Common::change_message(msg, object, attr_hash)
    # NOTE: object may be another hash. all fields are referenced through object[]
    # go through each parameter in attr_hash and if present in object and value is different, describe change in message returned
    # if no changes present, message is nil
    return nil if attr_hash.nil?
    change_msgs = []
    Common::detect_changes(object, attr_hash).each do |key, values|
      v_from = (values[:old].nil? ? '<NIL>' : "'#{values[:old].to_s}'")
      v_to = (values[:new].nil? ? '<NIL>' : "'#{values[:new].to_s}'")
      change_msgs << "#{key} changed from #{v_from} to #{v_to}"
    end
    if change_msgs.empty?
      return nil
    else
      return msg + change_msgs.join('; ')
    end
  end
end
