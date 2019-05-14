describe "MiqAeMockService" do
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('a' => 1, 'b' => 2)
  end
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:current_object) { Spec::Support::MiqAeMockObject.new('x' => 11, 'y' => 21) }

  it "#current" do
    ae_service.current_object = current_object

    expect(ae_service.current['x']).to eq(11)
  end
end
