require 'byebug'

describe MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask do
  let(:user) { FactoryGirl.create(:user_with_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }

  before(:each) do
    Spec::Support::MiqAutomateHelper.create_service_model_method('SPEC_DOMAIN', 'EVM', 'AUTOMATE', 'test1', 'test')
    @ae_method = ::MiqAeMethod.first
  end

  def invoke_ae
    MiqAeEngine.instantiate("/EVM/AUTOMATE/test1?ServiceTemplateTransformationPlanTask::service_template_transformation_plan_task=#{task.id}", user)
  end

  describe "#conversion_host=" do
    before(:each) do
      @conversion_host = FactoryGirl.create(:conversion_host)
    end

    it "removes the conversion host if arg is nil" do
      task.conversion_host = @conversion_host
      method = "$evm.root['#{@ae_result_key}'] = $evm.root['service_template_transformation_plan_task'].conversion_host = nil"
      @ae_method.update_attributes(:data => method)
      invoke_ae
      expect(task.reload.conversion_host).to be_nil
    end

    it "sets the conversion host if arg is not nil" do
      method = "$evm.root['#{@ae_result_key}'] = $evm.root['service_template_transformation_plan_task'].conversion_host = $evm.vmdb('conversion_host').first"
      @ae_method.update_attributes(:data => method)
      invoke_ae
      expect(task.reload.conversion_host).to eq(@conversion_host)
    end
  end
end
