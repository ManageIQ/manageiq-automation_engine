describe MiqAeMethodService::MiqAeServiceServiceReconfigureRequest do
  include Spec::Support::AutomationHelper

  before do
    method_script   = "$evm.root['ci_type'] = $evm.root['request'].ci_type"
    create_ae_model_with_method(:method_script => method_script, :ae_class => 'AUTOMATE',
                                :ae_namespace  => 'EVM', :instance_name => 'test1',
                                :method_name   => 'test', :name => 'TEST_DOMAIN')
  end

  let(:ae_method)     { ::MiqAeMethod.first }
  let(:user)          { FactoryBot.create(:user_with_group) }
  let(:request)       { FactoryBot.create(:service_reconfigure_request, :requester => user) }

  def invoke_ae
    MiqAeEngine.instantiate("/EVM/AUTOMATE/test1?ServiceReconfigureRequest::request=#{request.id}", user)
  end

  it "returns 'service' for ci_type" do
    expect(invoke_ae.root('ci_type')).to eq('service')
  end
end
