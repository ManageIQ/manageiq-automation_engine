describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_TemplateRunner do
  it "get the service model class" do
    expect { described_class }.not_to raise_error
  end

  it "#signal" do
    expect(described_class.instance_methods).to include(:signal)
  end

  it "#wait_on_ansible_job" do
    expect(described_class.instance_methods).to include(:wait_on_ansible_job)
  end

  it ".create_job" do
    args = {:param1 => 'something', :param2 => 2}
    expect(ManageIQ::Providers::AnsibleTower::AutomationManager::TemplateRunner).to receive(:create_job).with(args).once
    described_class.create_job(args)
  end
end
