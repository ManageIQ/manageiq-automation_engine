describe "MiqAeDeserializeWorkspace" do
  let(:test_class) do
    Class.new do
      include MiqAeEngine::MiqAeDeserializeWorkspace
      attr_reader :persist_state_hash
      def initialize(workspace)
        @workspace = workspace
        @persist_state_hash = {}
      end

      def root
        @workspace.root
      end

      def ae_user
        @workspace.ae_user
      end
    end
  end

  let(:user) do
    FactoryGirl.create(:user_with_group,
                       :userid   => "admin",
                       :settings => {:display => { :timezone => "UTC"}})
  end

  let(:workspace) do
    double("MiqAeEngine::MiqAeWorkspaceRuntime", :root => root_object, :ae_user => user)
  end

  let(:test_class_instance) { test_class.new(workspace) }
  let(:host) { FactoryGirl.create(:host) }
  let(:vm_name) { "Freddy Krueger" }
  let(:vm) { FactoryGirl.create(:vm_vmware, :host => host, :name => vm_name) }

  describe "#update_workspace" do
    context "caller adds a vm object as attribute" do
      let(:root_hash) { { 'a' => 1, 'b' => '2'} }
      let(:updated_hash) do
        {
          'state_vars' => { 'x' => 1 },
          'objects'    => {
            'root'                => {
              'a'     => 9,
              'my_vm' => "vmdb_reference::#{vm.href_slug}",
              'd'     => '2'
            },
            '/miq/demo/test/ins1' => {
              'z' => 42
            }
          }
        }
      end

      let(:invalid_obj_name_hash) do
        {'objects' => { 'frooti' => {} }}
      end

      let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
      let(:child_object) { Spec::Support::MiqAeMockObject.new(root_hash) }

      it "check updated values" do
        child_object.namespace = "miq/demo"
        child_object.klass     = 'test'
        child_object.instance  = 'ins1'
        child_object.link_parent_child(root_object, child_object)

        test_class_instance.update_workspace(updated_hash)

        expect(root_object['a']).to eq(9)
        expect(root_object['d']).to eq('2')
        expect(root_object['my_vm'].name).to eq(vm_name)
        expect(child_object['z']).to eq(42)
        expect(test_class_instance.persist_state_hash['x']).to eq(1)
      end

      it "raises error with invalid object name" do
        expect do
          test_class_instance.update_workspace(invalid_obj_name_hash)
        end.to raise_exception(MiqAeException::Error)
      end
    end
  end
end
