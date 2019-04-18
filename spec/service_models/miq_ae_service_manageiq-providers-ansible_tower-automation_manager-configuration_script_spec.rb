describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_ConfigurationScript do
  it "get the service model class" do
    expect { described_class }.not_to raise_error
  end

  it "#run" do
    expect(described_class.instance_methods).to include(:run)
  end

  it "#create_job" do
    template = FactoryBot.create(:ansible_configuration_script)
    svc_template = described_class.find(template.id)
    expect(ManageIQ::Providers::AnsibleTower::AutomationManager::Job).to receive(:create_job)

    svc_template.create_job({})
  end
end
