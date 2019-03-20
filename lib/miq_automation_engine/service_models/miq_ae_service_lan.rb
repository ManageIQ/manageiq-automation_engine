module MiqAeMethodService
  class MiqAeServiceLan < MiqAeServiceModelBase
    expose :templates,     :association => true, :method => :miq_templates
  end
end
