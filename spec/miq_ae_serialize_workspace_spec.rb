describe "MiqAeSerializeWorkspace" do
  let(:test_class) do
    Class.new do
      include MiqAeEngine::MiqAeSerializeWorkspace
      def initialize(workspace)
        @workspace = workspace
      end

      def get_value(_f, type)
        @workspace.root[type]
      end

      def get_obj_from_path(_path)
        @workspace.root
      end

      def roots
        [@workspace.root]
      end
    end
  end

  let(:workspace) { double("MiqAeEngine::MiqAeWorkspaceRuntime", :root => root_object) }
  let(:test_class_instance) { test_class.new(workspace) }
  let(:user) do
    FactoryGirl.create(:user_with_group, :userid   => "admin",
                                         :settings => {:display => { :timezone => "UTC"}})
  end

  let(:host) { FactoryGirl.create(:host) }
  let(:vm) { FactoryGirl.create(:vm_vmware, :host => host) }
  let(:svc_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }

  describe "#hash_workspace" do
    context "simple attributes" do
      let(:root_hash) { { 'a' => 1, 'b' => '2'} }
      let(:hashed_workspace) { { "root" => root_hash} }
      let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }

      it "return a simple hash" do
        expect(test_class_instance.hash_workspace).to eq(hashed_workspace)
      end
    end

    context "vmdb_object" do
      let(:root_hash) { { 'a' => 1, 'b' => '2', 'my_vm' => svc_vm} }
      let(:ref_hash) { { 'a' => 1, 'b' => '2', 'my_vm' => "href_slug::#{vm.href_slug}"} }
      let(:hashed_workspace) { { "root" => ref_hash} }
      let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }

      it "return a simple hash with the vm reference" do
        expect(test_class_instance.hash_workspace).to eq(hashed_workspace)
      end
    end

    context "object graph" do
      let(:root_hash) { { 'a' => 1, 'b' => '2' } }
      let(:child_hash) { { 'age' => 55 } }
      let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
      let(:child_object) { Spec::Support::MiqAeMockObject.new(child_hash) }

      it "returns a nested hash" do
        child_object.namespace = "manageiq/bedrock"
        child_object.klass     = "mogul"
        child_object.instance  = "fred"

        child_object.link_parent_child(root_object, child_object)
        result = { "root"                         => {"a" => 1, "b" => "2"},
                   "/manageiq/bedrock/mogul/fred" => {"age" => 55, "::miq::parent" => "root"}}
        expect(test_class_instance.hash_workspace).to eq(result)
      end
    end
  end
end
