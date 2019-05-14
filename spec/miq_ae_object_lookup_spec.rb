describe "MiqAeObjectLookup" do
  let(:test_class) do
    Class.new do
      include MiqAeEngine::MiqAeObjectLookup
      def initialize
        initialize_obj_entries
      end
    end
  end

  let(:test_instance) { test_class.new }
  let(:obj1) { double("OBJ", :fqns => 'Dom1/A/B', :klass => 'CLASS1', :instance => 'INSTANCE1') }
  let(:obj2) { double("OBJ", :fqns => 'Dom1/C/D', :klass => 'CLASS1', :instance => 'INSTANCE1') }
  let(:obj3) { double("OBJ", :fqns => 'Dom1/E/F', :klass => 'CLASS2', :instance => 'INSTANCE2') }

  describe "#find_obj_entry" do
    before do
      test_instance.add_obj_entry(obj1.fqns, obj1.klass, obj1.instance, obj1)
      test_instance.add_obj_entry(obj2.fqns, obj2.klass, obj2.instance, obj2)
      test_instance.add_obj_entry(obj3.fqns, obj3.klass, obj3.instance, obj3)
    end

    context "domain qualified" do
      it "return a valid object with leading slash" do
        expect(test_instance.find_obj_entry('/Dom1/A/B/class1/instance1')).to eq(obj1)
      end

      it "return a valid object without leading slash" do
        expect(test_instance.find_obj_entry('Dom1/A/B/class1/instance1')).to eq(obj1)
      end
    end

    context "namespace qualified" do
      it "return a valid object with leading slash" do
        expect(test_instance.find_obj_entry('/C/d/ClASs1/instance1')).to eq(obj2)
      end

      it "return a valid object without leading slash" do
        expect(test_instance.find_obj_entry('C/d/class1/instance1')).to eq(obj2)
      end
    end

    context "glob in instance name" do
      it "return a valid object with leading slash" do
        expect(test_instance.find_obj_entry('/C/d/ClASs1/i?stance1')).to eq(obj2)
      end

      it "return a valid object with *" do
        expect(test_instance.find_obj_entry('/C/d/ClASs1/*')).to eq(obj2)
      end
    end

    context "object not found" do
      it "return a nil" do
        expect(test_instance.find_obj_entry('/Dom5/A/B/class1/instance1')).to be_nil
      end
    end

    context "invalid path" do
      it "returns nil" do
        expect(test_instance.find_obj_entry('A/B')).to be_nil
      end
    end
  end
end
