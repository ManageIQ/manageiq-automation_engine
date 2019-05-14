module MiqAeMethodService
  class MiqAeServicePxeServer < MiqAeServiceModelBase
    expose :images,                        :association => true
    expose :advertised_images,             :association => true
    expose :discovered_images,             :association => true
    expose :default_pxe_image_for_windows, :association => true
  end
end
