require 'manageiq-password'

class MiqAePassword < ManageIQ::Password
  def self.encrypt(str)
    return str if str.blank? || self.encrypted?(str)
    ManageIQ::Password.encrypt(str)
  end

  def self.decrypt(str)
    ManageIQ::Password.decrypt(str)
  end

  def self.decrypt_if_password(obj)
    obj.kind_of?(MiqAePassword) ? ManageIQ::Password.decrypt(obj.encStr) : obj
  end

  def to_s
    MASK
  end

  def inspect
    "\"#{self}\""
  end
end
