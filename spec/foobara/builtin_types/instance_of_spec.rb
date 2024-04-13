RSpec.describe Foobara::BuiltinTypes::Duck::SupportedValidators::OneOf do
  let(:type) do
    Foobara::GlobalDomain.foobara_type_from_declaration(*Foobara::Util.array(type_declaration))
  end

  before do
    stub_class("Foo")
  end

  context "when class" do
    let(:type_declaration) { Foo }

    it "desugarizes as a duck and works as a duck but validates instance of" do
      expect(type.declaration_data).to eq(type: :duck, instance_of: "Foo")

      foo = Foo.new
      expect(type.process_value!(foo)).to be(foo)

      not_foo = Object.new
      outcome = type.process_value(not_foo)
      expect(outcome).to_not be_success
      errors = outcome.errors
      expect(errors.size).to eq(1)
      error = errors.first
      expect(error).to be_a(Foobara::BuiltinTypes::Duck::SupportedValidators::InstanceOf::NotInstanceOfError)
      expect(error.message).to match(/is not an instance of Foo/)
    end
  end

  context "when :duck with instance_of: processor declaration" do
    let(:type_declaration) do
      [:duck, { instance_of: :Foo }]
    end

    it "casts instance_of: to a string" do
      expect(type.declaration_data).to eq(type: :duck, instance_of: "Foo")
    end

    context "when intance_of: some class" do
      let(:type_declaration) do
        [:duck, { instance_of: Foo }]
      end

      it "casts instance_of: to a string" do
        expect(type.declaration_data).to eq(type: :duck, instance_of: "Foo")
      end
    end
  end

  context "when not the name of an existing class" do
    let(:type_declaration) do
      [:duck, { instance_of: "NotAnExistingClassName" }]
    end

    it "explodes" do
      expect {
        type
      }.to raise_error(Foobara::BuiltinTypes::Duck::SupportedValidators::InstanceOf::TypeDeclarationExtension::
          ExtendRegisteredTypeDeclaration::TypeDeclarationValidators::IsValidClass::InvalidInstanceOfValueGivenError)
    end
  end

  context "when not something that can be desugarized at all" do
    let(:type_declaration) do
      [:duck, { instance_of: 100 }]
    end

    it "explodes" do
      expect {
        type
      }.to raise_error(Foobara::BuiltinTypes::Duck::SupportedValidators::InstanceOf::TypeDeclarationExtension::
          ExtendRegisteredTypeDeclaration::TypeDeclarationValidators::IsValidClass::InvalidInstanceOfValueGivenError)
    end
  end
end
