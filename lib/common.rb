module Common
  PASSWORD_MIN_LENGTH = 6
  INVALID_PASSWORD_MESSAGE = "is invalid. Password must be at least #{PASSWORD_MIN_LENGTH} characters long, contain at least one upper-case letter, one lower-case letter and one number or special character; and must not contain 'password' or the username."
  def Common.valid_password?(password, username = '')
    return false if password.blank?
    return false unless PASSWORD_MIN_LENGTH <= password.length
    return false unless password.match(/[A-Z]/)
    return false unless password.match(/[a-z]/)
    return false unless password.match(/[0-9\?\!\@\#\$\%\^\&\*\(\)\[\]\{\}\=\+\-]/)
    return false if password.downcase == username.downcase
    return false if password.match(/password/i)
    return true
  end
  
  PASSWORD_CHARS = 'abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ23456789'
  def Common::random_password(username, size = 6)
    password = ''
    while(!valid_password?(password, username))
      password = ''
      size.times do
        password += PASSWORD_CHARS[rand(PASSWORD_CHARS.length), 1]
      end
    end
    return password
  end
  
  URL_FRIENDLY_CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
  def Common::random_token(size = 32)
    token = ''
    size.times do
      token += URL_FRIENDLY_CHARS[rand(URL_FRIENDLY_CHARS.length)]
    end
    return token
  end
  
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

  def Common.value_to_boolean(value)
    return false if value.nil?
    return value if value == true || value == false
    case value.to_s.downcase
    when "true", "t", "1", "y", "yes", "on" then true
    else false
    end
  end
end
