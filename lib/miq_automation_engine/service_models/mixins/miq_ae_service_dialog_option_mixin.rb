module MiqAeServiceDialogOptionMixin
  def get_dialog_option(key)
    object_send(:get_dialog_option, key)
  end

  def get_dialog_option_decrypted(key)
    object_send(:get_dialog_option_decrypted, key)
  end

  def dialog_option_encrypted?(key)
    object_send(:dialog_option_encrypted?, key)
  end
end
