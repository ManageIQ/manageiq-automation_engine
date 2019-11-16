module MiqAeMethodService
  class MiqAeServiceServiceTemplateAnsiblePlaybook < MiqAeServiceServiceTemplateGeneric
    expose :config_info, :association => true
    expose :job_template
  end
end
