describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_ConfigurationWorkflow do
  it "get the service model class" do
    expect { described_class }.not_to raise_error
  end

  it "#run" do
    expect(described_class.instance_methods).to include(:run)
  end

  it "#create_job" do
    workflow_template = FactoryBot.create(:configuration_workflow)
    svc_workflow_template = described_class.find(workflow_template.id)
    expect(ManageIQ::Providers::AnsibleTower::AutomationManager::WorkflowJob).to receive(:create_job)

    svc_workflow_template.create_job({})
  end
end
