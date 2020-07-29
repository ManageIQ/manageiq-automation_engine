describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager do
  let(:provider) { FactoryBot.create(:provider_ansible_tower) }
  let!(:automation_manager) { FactoryBot.create(:automation_manager_ansible_tower, :provider => provider) }

  it "get the service model" do
    svc = described_class.find(automation_manager.id)

    ems = ExtManagementSystem.find(automation_manager.ext_management_system.id)
    expect(svc.name).to eq(ems.name)
  end
end
