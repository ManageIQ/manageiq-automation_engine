module MiqAeMethodService
  class MiqAeServiceServiceTemplate < MiqAeServiceModelBase
    def owner=(owner)
      if owner.nil? || owner.kind_of?(MiqAeMethodService::MiqAeServiceUser)
        @object.evm_owner = if owner.nil?
                              nil
                            else
                              User.find_by(:id => owner.id)
                            end
        @object.save
      end
    end

    def group=(group)
      if group.nil? || group.kind_of?(MiqAeMethodService::MiqAeServiceMiqGroup)
        @object.miq_group = if group.nil?
                              nil
                            else
                              MiqGroup.find_by(:id => group.id)
                            end
        @object.save
      end
    end
  end
end
