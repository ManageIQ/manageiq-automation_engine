describe MiqAeEngine::MiqAeWorkspaceRuntime do
  let(:root_tenant) { Tenant.seed }
  let(:user) { FactoryGirl.create(:user_with_group) }
  before do
    EvmSpecHelper.local_miq_server
  end

  describe "#instantiate" do
    it "returns workspace" do
      expect(MiqAeEngine::MiqAeWorkspaceRuntime.instantiate("/a/b/c", user)).to be_a_kind_of(MiqAeEngine::MiqAeWorkspaceRuntime) 
    end
  end
end
