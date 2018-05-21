describe MiqAeEngine::MiqAeObject do
  include Spec::Support::AutomationHelper

  context "Expression" do
    let(:user) { FactoryGirl.create(:user_with_group) }
    let(:instance_name) { 'Pebbles' }
    let(:parent_instance_name) { 'Wilma' }
    let(:vm_name) { "BammBammRubble" }
    let(:vm) { FactoryGirl.create(:vm, :name => vm_name) }
    let(:ems) { FactoryGirl.create(:ems_vmware) }
    let(:number_of_vms) { 999 }
    let(:vm_template) do
      FactoryGirl.create(:template_vmware, :name                  => "template1",
                                           :ext_management_system => ems)
    end
    let(:miq_provision_request) do
      FactoryGirl.create(:miq_provision_request,
                         :requester => user,
                         :src_vm_id => vm_template.id,
                         :options   => {:number_of_vms => number_of_vms})
    end

    let(:ae_instances) do
      {instance_name => {'var1'  => {:value => "ok"},
                         'guard' => {:value => assert_value}}}
    end

    let(:ae_fields) do
      {'var1'  => {:aetype => 'attribute', :datatype => 'string'},
       'guard' => {:aetype => 'assertion', :datatype => 'string'}}
    end

    let(:ae_model) do
      create_ae_model(:name => 'Flintstones', :ae_class => 'Kids',
                      :ae_namespace => 'A/C',
                      :ae_fields => ae_fields, :ae_instances => ae_instances)
    end

    let(:parent_fields) do
      {'rel1' => {:aetype => 'relationship', :datatype => 'string'}}
    end

    let(:parent_model) do
      create_ae_model(:name => 'Fred', :ae_class => 'Family',
                      :ae_namespace => 'X/Y',
                      :ae_fields => parent_fields, :ae_instances => parent_instances)
    end

    let(:child_name) { "/A/C/Kids/#{instance_name}" }

    let(:parent_instances) do
      {parent_instance_name => {'rel1' => {:value => child_name} }}
    end

    let(:automate_url) do
      "/X/Y/Family/Wilma?Vm::vm=#{vm.id}&MiqProvisionRequest::miq_provision_request=#{miq_provision_request.id}"
    end

    let(:child_url) do
      "/Flintstones/A/C/Kids/Pebbles"
    end

    context "missing object" do
      let(:assert_value) { "${/missing_object#var1}" }

      it "raises ObjectNotFound" do
        ae_model

        expect do
          MiqAeEngine.instantiate(child_url, user)
        end.to raise_exception(MiqAeException::ObjectNotFound)
      end
    end

    context "missing attribute" do
      let(:assert_value) { "${/#var1}" }

      it "raises AttributeNotFound" do
        ae_model

        expect do
          MiqAeEngine.instantiate(child_url, user)
        end.to raise_exception(MiqAeException::AttributeNotFound)
      end
    end

    shared_examples_for "assertion_passes" do
      it "resolves" do
        parent_model
        ae_model
        workspace = MiqAeEngine.instantiate(automate_url, user)

        expect(workspace.nodes.last.attributes['var1']).to eq("ok")
        expect(workspace.nodes.last.object_name).to eq(child_url)
        expect(workspace.nodes.count).to eq(2)
      end
    end

    shared_examples_for "assertion_fails" do
      it "does not resolve" do
        parent_model
        ae_model
        workspace = MiqAeEngine.instantiate(automate_url, user)
        expect(workspace.nodes.count).to eq(1)
      end
    end

    context "true" do
      let(:assert_value) { "true" }
      it_behaves_like "assertion_passes"
    end

    context "false" do
      let(:assert_value) { "false" }
      it_behaves_like "assertion_fails"
    end

    context "${/#vm.name.length} >= 4" do
      let(:assert_value) { "${/#vm.name.length} >= ".concat(vm.name.length.to_s) }
      it_behaves_like "assertion_passes"
    end

    context "${/#vm.name} != 'Fred'" do
      let(:assert_value) { "${/#vm.name} != ".concat("'#{vm_name}'") }
      it_behaves_like "assertion_fails"
    end

    context "${/#vm.name} == 'Fred'" do
      let(:assert_value) { "'${/#vm.name}' == ".concat("'#{vm_name}'") }
      it_behaves_like "assertion_passes"
    end

    context "${/#miq_provision_request.get_option(:number_of_vms)} == 9" do
      let(:assert_value) do
        "${/#miq_provision_request.get_option(:number_of_vms)} == "
          .concat(number_of_vms.to_s)
      end
      it_behaves_like "assertion_passes"
    end

    context "${/#miq_provision_request.get_option(:number_of_vms)} == 9 &&  ${/#vm.name} == 'Fred'" do
      let(:assert_value) do
        "${/#miq_provision_request.get_option(:number_of_vms)} == "
          .concat(number_of_vms.to_s)
          .concat(" && '${/#vm.name}' == ").concat("'#{vm_name}'")
      end
      it_behaves_like "assertion_passes"
    end

    context "${/#miq_provision_request.get_option(:number_of_vms)} != 9 ||  ${/#vm.name} == 'Fred'" do
      let(:assert_value) do
        "${/#miq_provision_request.get_option(:number_of_vms)} != "
          .concat(number_of_vms.to_s)
          .concat(" || '${/#vm.name}' == ").concat("'#{vm_name}'")
      end
      it_behaves_like "assertion_passes"
    end

    context "%w(${/#vm.name} Hoppy).include? 'Fred'" do
      let(:assert_value) do
        "%w(${/#vm.name} Hoppy)"
          .concat(".include?")
          .concat(" '${/#vm.name}' ")
      end
      it_behaves_like "assertion_passes"
    end
  end
end
