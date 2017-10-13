describe MiqAeEngine::MiqAeReference do
  context "vmdb objects" do
    let(:user) do
      FactoryGirl.create(:user_with_group, :userid   => "admin",
                                           :settings => {:display => { :timezone => "UTC"}})
    end
    let(:host) { FactoryGirl.create(:host) }
    let(:vm) { FactoryGirl.create(:vm_vmware, :host => host) }
    let(:svc_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
    let(:ref) { "href_slug::#{vm.href_slug}" }

    it "#encode a vm object" do
      expect(::MiqAeEngine::MiqAeReference.encode(svc_vm)).to eq(ref)
    end

    it "#decode a vm reference" do
      expect(::MiqAeEngine::MiqAeReference.decode(ref, user).id).to eq(vm.id)
    end
  end

  context "passwords" do
    let(:user) do
      FactoryGirl.create(:user_with_group, :userid   => "admin",
                                           :settings => {:display => { :timezone => "UTC"}})
    end
    let(:password) { "ca$hc0w" }
    let(:miq_password) { MiqAePassword.new(password) }
    let(:enc_password) { "password::#{miq_password.encStr}" }

    it "#encodes a password field" do
      expect(::MiqAeEngine::MiqAeReference.encode(miq_password)).to eq(enc_password)
    end

    it "#decodes a password field" do
      expect(::MiqAeEngine::MiqAeReference.decode(enc_password, user).encStr).to eq(miq_password.encStr)
    end
  end
end
