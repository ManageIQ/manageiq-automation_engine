describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_HostEsx do
  let(:host) { FactoryBot.create(:host_vmware_esx, :ext_management_system => FactoryBot.create(:ext_management_system)) }
  let(:svc_host) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_HostEsx.find(host.id) }

  it "#shutdown async" do
    @base_queue_options = {
      :class_name  => host.class.name,
      :instance_id => host.id,
      :zone        => host.my_zone,
      :role        => 'ems_operations',
      :queue_name  => host.queue_name_for_ems_operations,
      :task_id     => nil
    }
    svc_host.shutdown

    expect(MiqQueue.last).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'vim_shutdown',
        :args        => [false]
      )
    )
  end
end
