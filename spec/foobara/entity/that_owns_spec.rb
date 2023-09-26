RSpec.describe Foobara::Entity do
  # Entity types:
  #
  # one-to-one (default for foo: Bar attribute)
  # one-to-many (default for foo: [Bar] attribute)
  # many-to-one
  # many-to-many
  #
  # .that_own is for many-to-*
  # .that_owns is for one-to-*
  #
  # To specify many-to-* one must add:
  #
  # associations: {
  #   foo: {
  #     cardinality: "many-to-one"
  #   }
  # }
  #
  # otherwise an exception will be thrown from .that_own
  describe ".that_owns" do
    after do
      Foobara.reset_alls
    end

    before do
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

      stub_class = ->(klass) { stub_const(klass.name, klass) }

      Class.new(Foobara::Entity) do
        class << self
          def name
            "User"
          end
        end

        stub_class.call(self)

        attributes id: :integer,
                   name: :string

        primary_key :id
      end

      Class.new(Foobara::Entity) do
        class << self
          def name
            "Applicant"
          end
        end

        stub_class.call(self)

        attributes id: :integer,
                   user: User

        primary_key :id
      end

      Class.new(Foobara::Entity) do
        class << self
          def name
            "Package"
          end
        end

        stub_class.call(self)

        attributes id: :integer,
                   applicants: [Applicant],
                   is_active: :boolean

        primary_key :id
      end

      Class.new(Foobara::Entity) do
        class << self
          def name
            "Assignment"
          end
        end

        stub_class.call(self)

        attributes id: :integer,
                   package: Package

        primary_key :id
      end

      Class.new(Foobara::Entity) do
        class << self
          def name
            "Employee"
          end
        end

        stub_class.call(self)

        attributes id: :integer,
                   user: User,
                   assignments: { type: :array, element_type_declaration: Assignment, default: [] },
                   past_assignments: [Assignment]

        primary_key :id

        association :past_users, "past_assignments.#.package.applicants.#.user"
      end

      User.transaction do
        applicants = []
        employees = []
        packages  = []

        10.times do |i|
          user = User.create(name: "applicant user#{i}")
          applicants << Applicant.create(user:)
        end

        10.times do |i|
          user = User.create(name: "employee user#{i}")
          employees << Employee.create(user:)
        end

        20.times do |i|
          packages << Package.create(is_active: i < 3, applicants: [applicants[i % 3]])
        end

        15.times do |i|
          package = packages[i]

          assignment = Assignment.create(package:)

          if i < 10
            employees[i % 4].assignments += [assignment]

            if i.even?
              employees[(i % 4) + 1].assignments += [assignment]
            end
          else
            employees[0].past_assignments ||= []
            employees[0].past_assignments += [assignment]
          end
        end
      end
    end

    it "can find the appropriate records through various that_owns/that_own calls", :focus do
      User.transaction do
        expect(Employee.all[1].past_users).to eq([])
        expect(Employee.all[0].past_users).to contain_exactly(User.thunk(1), User.thunk(2), User.thunk(3))

        applicant = Applicant.all.first
        user = applicant.user

        expect(Applicant.that_owns(user)).to be(applicant)
        $stop = true
        expect(Employee.that_owns(User.thunk(1), "past_")).to eq(Employee.all.first)
      end
    end
  end
end
