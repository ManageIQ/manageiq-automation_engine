module MiqAeMethodService
  class MiqAeServiceServiceTemplateCatalog < MiqAeServiceModelBase
    expose :service_template_catalogs, :association => true
    expose :service_templates,         :association => true
    expose :tenant,                    :association => true
  end
end
