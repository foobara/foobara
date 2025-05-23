RSpec.describe Foobara::Model do
  after do
    Foobara.reset_alls
  end

  describe ".delegate_attribute" do
    let(:auth_user_class) do
      stub_class(:AuthUser, described_class) do
        attributes do
          username :string, :required
          email :string
        end
      end
    end
    let(:user_class) do
      auth_user

      stub_class(:User, described_class) do
        attributes do
          auth_user AuthUser, :required
          some_attribute :integer
        end
      end.tap do |klass|
        klass.delegate_attribute(:username, [:auth_user, :username], writer:)
      end
    end

    let(:writer) { nil }
    let(:auth_user) { auth_user_class.new(username:, email:) }
    let(:username) { "Basil" }
    let(:email) { "basil@foobara.com" }

    let(:user) { user_class.new(auth_user:) }

    let(:manifest) { user_class.model_type.foobara_manifest }

    context "when defining models using classes" do
      it "creates a reader" do
        expect(user.username).to eq(username)
        expect(user).to_not respond_to("username=")
        expect(user).to_not respond_to(email)
      end

      it "contains the delegated attribute in the attributes_type" do
        expect(manifest[:attributes_type][:element_type_declarations][:username]).to eq(
          type: :string
        )
      end

      it "includes the delegate info in the manifest" do
        expect(manifest[:delegates]).to eq(
          username: {
            data_path: "auth_user.username"
          }
        )

        expect(manifest[:declaration_data][:delegates]).to eq(
          username: {
            data_path: "auth_user.username"
          }
        )
      end

      context "when creating writer method" do
        let(:writer) { true }

        it "creates a writer" do
          expect(user.username).to eq(username)
          expect(user).to respond_to("username=")
          expect(user).to_not respond_to(email)

          expect {
            user.username = "Barbara"
          }.to change(user, :username).to("Barbara")
        end

        it "includes the delegate info in the manifest" do
          expect(manifest[:delegates]).to eq(
            username: {
              data_path: "auth_user.username",
              writer: true
            }
          )

          expect(manifest[:declaration_data][:delegates]).to eq(
            username: {
              data_path: "auth_user.username",
              writer: true
            }
          )
        end
      end
    end

    context "when defining models using type declarations" do
      let(:auth_user_declaration) do
        {
          type: :model,
          name: "AuthUser",
          attributes_declaration: {
            type: :attributes,
            element_type_declarations: {
              username: { type: :string },
              email: { type: :string }
            },
            required: [:username]
          },
          delegates: {}
        }
      end

      let(:user_declaration) do
        {
          type: :model,
          name: "User",
          attributes_declaration: {
            type: :attributes,
            element_type_declarations: {
              auth_user: { type: :AuthUser }
            },
            required: [:auth_user]
          },
          delegates:
        }
      end

      let(:delegates) do
        { username: { data_path: "auth_user.username", writer: } }
      end

      let(:auth_user_class) do
        Foobara::Domain.current.foobara_type_from_declaration(auth_user_declaration).target_class
      end

      let(:user_class) do
        auth_user_class
        Foobara::Domain.current.foobara_type_from_declaration(user_declaration).target_class
      end

      it "creates anonymous classes" do
        expect(auth_user_class.name).to be_nil
        expect(user_class.name).to be_nil
      end

      it "creates a reader" do
        expect(user.username).to eq(username)
        expect(user).to_not respond_to("username=")
        expect(user).to_not respond_to(email)
      end

      it "includes the delegate info in the manifest" do
        expect(manifest[:delegates]).to eq(
          username: {
            data_path: "auth_user.username"
          }
        )

        expect(manifest[:declaration_data][:delegates]).to eq(
          username: {
            data_path: "auth_user.username"
          }
        )
      end

      context "when delegates is invalid" do
        context "when it is not a hash" do
          let(:delegates) { "not a hash" }

          it "cannot create the type" do
            expect {
              user_class
            }.to raise_error(
              Foobara::TypeDeclarations::Handlers::ExtendModelTypeDeclaration::DelegatesValidator::InvalidDelegatesError
            )
          end
        end

        context "when it has a bad key" do
          let(:delegates) do
            { username: { data_path: "auth_user.username", bad_key: 100 } }
          end

          it "cannot create the type" do
            expect {
              user_class
            }.to raise_error(
              Foobara::TypeDeclarations::Handlers::ExtendModelTypeDeclaration::DelegatesValidator::InvalidDelegatesError
            )
          end
        end
      end

      context "when creating writer method" do
        let(:writer) { true }

        it "creates a writer" do
          expect(user.username).to eq(username)
          expect(user).to respond_to("username=")
          expect(user).to_not respond_to(email)

          expect {
            user.username = "Barbara"
          }.to change(user, :username).to("Barbara")
        end

        it "includes the delegate info in the manifest" do
          expect(manifest[:delegates]).to eq(
            username: {
              data_path: "auth_user.username",
              writer: true
            }
          )

          expect(manifest[:declaration_data][:delegates]).to eq(
            username: {
              data_path: "auth_user.username",
              writer: true
            }
          )
        end
      end
    end
  end

  describe ".private_attribute" do
    let(:auth_user_class) do
      stub_class(:AuthUser, described_class) do
        attributes do
          username :string, :required
          email :string
          ssn :string
        end

        private_attribute(:ssn)
      end
    end
    let(:user_class) do
      auth_user

      stub_class(:User, described_class) do
        attributes do
          auth_user AuthUser, :required, :private
          some_attribute :integer
        end

        delegate_attribute(:username, :auth_user)
      end
    end

    let(:auth_user) { auth_user_class.new(username:, email:) }
    let(:username) { "Basil" }
    let(:email) { "basil@foobara.com" }
    let(:some_attribute) { 100 }

    let(:user) { user_class.new(auth_user:, some_attribute:) }

    let(:manifest) { user_class.model_type.foobara_manifest }

    context "when defining models using classes" do
      it "hides the private attribute" do
        expect(user.username).to eq(username)
        expect(user.some_attribute).to eq(100)
        expect(user).to_not respond_to("username=")
        expect(user).to_not respond_to(:auth_user)
        expect(user_class.private_attribute_names).to eq([:auth_user])
        expect(auth_user).to_not respond_to(:ssn)
      end

      it "contains the private attribute in the manifest" do
        expect(manifest[:private]).to eq([:auth_user])
      end
    end

    context "with bad private attribute" do
      context "with a non-existent attribute name" do
        let(:user_declaration) do
          {
            type: :model,
            name: "User",
            attributes_declaration: {
              type: :attributes,
              element_type_declarations: {
                name: :string,
                password: :string
              },
              required: [:name, :password]
            },
            private: [:some_invalid_attribute]
          }
        end

        it "cannot create the type" do
          expect {
            Foobara::Domain.current.foobara_type_from_declaration(user_declaration)
          }.to raise_error(
            Foobara::TypeDeclarations::Handlers::ExtendModelTypeDeclaration::
                ValidAttributeNames::InvalidPrivateValueGivenError
          )
        end
      end

      context "with a non-string/symbol" do
        let(:user_declaration) do
          {
            type: :model,
            name: "User",
            attributes_declaration: {
              type: :attributes,
              element_type_declarations: {
                name: :string,
                password: :string
              },
              required: [:name, :password]
            },
            private: [Object.new]
          }
        end

        it "cannot create the type" do
          expect {
            Foobara::Domain.current.foobara_type_from_declaration(user_declaration)
          }.to raise_error(
            Foobara::TypeDeclarations::Handlers::ExtendModelTypeDeclaration::
                ArrayWithSymbolicElements::InvalidPrivateValuesGivenError
          )
        end
      end
    end

    context "when defining models using type declarations" do
      let(:auth_user_declaration) do
        {
          type: :model,
          name: "AuthUser",
          attributes_declaration: {
            type: :attributes,
            element_type_declarations: {
              username: { type: :string },
              email: { type: :string },
              ssn: { type: :string, private: true }
            },
            required: [:username]
          },
          delegates: {}
        }
      end

      let(:user_declaration) do
        {
          type: :model,
          name: "User",
          attributes_declaration: {
            type: :attributes,
            element_type_declarations: {
              auth_user: { type: :AuthUser },
              some_attribute: { type: :integer }
            },
            required: [:auth_user]
          },
          delegates:,
          private: ["auth_user"]
        }
      end

      let(:delegates) do
        { username: { data_path: "auth_user.username" } }
      end

      let(:auth_user_class) do
        Foobara::Domain.current.foobara_type_from_declaration(auth_user_declaration).target_class
      end

      let(:user_class) do
        auth_user_class
        Foobara::Domain.current.foobara_type_from_declaration(user_declaration).target_class
      end

      it "creates anonymous classes" do
        expect(auth_user_class.name).to be_nil
        expect(user_class.name).to be_nil
      end

      it "hides the private attribute" do
        expect(user.username).to eq(username)
        expect(user.some_attribute).to eq(100)
        expect(user).to_not respond_to(:auth_user)
        expect(user_class.private_attribute_names).to eq([:auth_user])
      end

      it "includes the private attribute name in the manifest" do
        expect(manifest[:private]).to eq([:auth_user])
      end
    end
  end
end
