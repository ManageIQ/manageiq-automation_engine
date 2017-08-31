describe MiqAeEngine::MiqAeReference do
  context "vmdb objects" do
    let(:user) do
      FactoryGirl.create(:user_with_group, :userid   => "admin",
                                           :settings => {:display => { :timezone => "UTC"}})
    end
    let(:host) { FactoryGirl.create(:host) }
    let(:vm) { FactoryGirl.create(:vm_vmware, :host => host) }
    let(:svc_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
    let(:ref) { "vmdb_reference::#{vm.href_slug}" }

    it "#encode a vm object" do
      expect(::MiqAeEngine::MiqAeReference.encode(svc_vm)).to eq(ref)
    end

    it "#decode a vm reference" do
      expect(::MiqAeEngine::MiqAeReference.decode(ref, user).id).to eq(vm.id)
    end
  end

  context "passwords" do
    let(:password) { MiqAePassword.new("smartvm") }

    it "#encodes a password field" do
      expect(::MiqAeEngine::MiqAeReference.encode(password)).to eq("miq_password::#{password}")
    end
  end
end
