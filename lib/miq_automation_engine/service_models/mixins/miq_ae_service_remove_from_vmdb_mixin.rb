module MiqAeServiceRemoveFromVmdb
  extend ActiveSupport::Concern

  def remove_from_vmdb
    _log.info("Removing #{@object.class.name} id:<#{@object.id}>, name:<#{@object.name}>")
    object_send(:destroy)
    @object = nil
    true
  end
end
