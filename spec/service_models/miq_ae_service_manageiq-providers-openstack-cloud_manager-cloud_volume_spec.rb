describe MiqAeMethodService::MiqAeServiceUser do
  let(:cloud_volume)         do
    FactoryBot.create(:cloud_volume_openstack, :ext_management_system => FactoryBot.create(:ems_openstack))
  end
  let(:service_cloud_volume) do
    MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager_CloudVolume.find(cloud_volume.id)
  end

  before do
    @base_queue_options = {
      :class_name  => cloud_volume.class.name,
      :instance_id => cloud_volume.id,
      :zone        => cloud_volume.ext_management_system.my_zone,
      :role        => 'ems_operations',
      :queue_name  => cloud_volume.queue_name_for_ems_operations,
      :task_id     => nil
    }
  end

  it "#backup_create async" do
    service_cloud_volume.backup_create('test backup', false)

    expect(MiqQueue.last).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'backup_create',
        :args        => [{:name => "test backup", :incremental => false}])
    )
  end

  it "#backup_restore async" do
    service_cloud_volume.backup_restore('1234')

    expect(MiqQueue.last).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'backup_restore',
        :args        => ["1234"])
    )
  end
end
