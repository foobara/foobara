RSpec.describe Foobara::Entity::Concerns::Initialization do
  describe "#run" do
    after do
      Foobara.reset_alls
    end

    before do
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    end

    let(:base_class) do
      stub_class = ->(klass) { stub_const(klass.name, klass) }

      Class.new(Foobara::Entity) do
        abstract

        class << self
          def name
            "Base"
          end
        end

        stub_class.call(self)

        attributes id: :integer

        primary_key :id
      end
    end

    let(:user_class) do
      stub_class = ->(klass) { stub_const(klass.name, klass) }

      Class.new(base_class) do
        class << self
          def name
            "User"
          end
        end

        stub_class.call(self)

        attributes name: { type: :string, required: true }
      end
    end

    let(:person_class) do
      user_class

      stub_class = ->(klass) { stub_const(klass.name, klass) }

      Class.new(base_class) do
        class << self
          def name
            "Person"
          end
        end

        abstract

        stub_class.call(self)

        attributes user: User
      end
    end

    let(:applicant_class) do
      stub_class = ->(klass) { stub_const(klass.name, klass) }

      Class.new(person_class) do
        class << self
          def name
            "Applicant"
          end
        end

        stub_class.call(self)

        attributes is_active: :boolean

        # TODO: make sure this isn't necessary outside of test suite where name is created later...
        set_model_type
      end
    end

    describe "creation through casting" do
      def type_for_declaration(...)
        Foobara::TypeDeclarations::Namespace.current.type_for_declaration(...)
      end

      let(:type) do
        type_for_declaration([Applicant])
      end

      it "can create the record and nested associations, too" do
        applicant_class.transaction do
          expect(type.registered_types_depended_on.map(&:type_symbol)).to match_array(
            %i[
              Applicant
              User
              array
              associative_array
              atomic_duck
              attributes
              boolean
              duck
              duckture
              entity
              integer
              model
              number
              string
            ]
          )

          applicants = type.process_value!([
                                             { user: { name: "Name1" }, is_active: false },
                                             { user: { name: "Name2" }, is_active: true },
                                             { user: { name: "Name3" }, is_active: false }
                                           ])

          expect(applicants).to all be_a(Applicant)
          expect(applicants.map(&:id)).to all be_nil
          expect(applicants.map(&:user).map(&:id)).to all be_nil

          applicant = Applicant.find_by_attribute(:is_active, true)
          expect(applicant.user.name).to eq("Name2")
        end

        User.transaction do
          applicants = Applicant.all.to_a

          expect(applicants).to all be_a(Applicant)
          expect(applicants.map(&:id)).to all be_a(Integer)
          expect(applicants.map(&:user).map(&:id)).to all be_a(Integer)

          applicant = Applicant.find_by_attribute(:is_active, true)
          expect(applicant.user.name).to eq("Name2")
        end
      end

      context "when not allowed to create an association via casting" do
        let(:user_class) do
          stub_class = ->(klass) { stub_const(klass.name, klass) }

          Class.new(base_class) do
            class << self
              def name
                "User"
              end

              def can_be_created_through_casting?
                false
              end
            end

            stub_class.call(self)

            attributes name: { type: :string, required: true }
          end
        end

        it "fails when creating by hash but works when creating by foreign key" do
          applicant_class.transaction do |tx|
            outcome = type.process_value(
              [
                { user: { name: "Name1" }, is_active: false },
                { user: { name: "Name2" }, is_active: true },
                { user: { name: "Name3" }, is_active: false }
              ]
            )

            expect(outcome).to_not be_success

            error_hash = outcome.errors_hash

            expect(error_hash.keys).to eq(
              [
                "data.0.user.cannot_cast",
                "data.1.user.cannot_cast",
                "data.2.user.cannot_cast"
              ]
            )

            expect(outcome.errors.first.path).to eq([0, :user])

            user1 = User.create(name: "Name1")
            user2 = User.create(name: "Name2")
            user3 = User.create(name: "Name3")

            tx.flush!

            outcome = type.process_value(
              [
                { user: user1.primary_key, is_active: false },
                { user: user2.primary_key, is_active: true },
                { user: user3.primary_key, is_active: false }
              ]
            )

            expect(outcome).to be_success
            applicants = Applicant.find_all_by_attribute(:is_active, true)
            expect(applicants.map(&:user).map(&:name)).to eq(["Name2"])
          end
        end
      end
    end
  end
end
