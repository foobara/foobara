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

      Class.new(Base) do
        class << self
          def name
            "User"
          end
        end

        stub_class.call(self)

        attributes name: { type: :string, required: true }
      end

      Class.new(Base) do
        class << self
          def name
            "Person"
          end
        end

        abstract

        stub_class.call(self)

        attributes user: User
      end

      Class.new(Person) do
        class << self
          def name
            "Applicant"
          end
        end

        stub_class.call(self)

        # TODO: make sure this isn't necessary outside of test suite where name is created later...
        set_model_type
      end

      Class.new(Base) do
        class << self
          def name
            "Package"
          end
        end

        stub_class.call(self)

        attributes applicants: [Applicant],
                   is_active: :boolean
      end

      Class.new(Base) do
        class << self
          def name
            "Assignment"
          end
        end

        stub_class.call(self)

        attributes package: Package
      end

      Class.new(Person) do
        class << self
          def name
            "Employee"
          end
        end

        stub_class.call(self)

        attributes assignments: { type: :array, element_type_declaration: Assignment, default: [] },
                   past_assignments: [Assignment],
                   priority_assignment: Assignment

        association :past_users, "past_assignments.#.package.applicants.#.user"
        association :priority_package, :"priority_assignment.package"
      end
    end

    it "can find the appropriate records through various that_owns/that_own calls" do
      expect(Employee.filtered_associations(:Assignment)).to eq(
        ["assignments.#", "past_assignments.#", "priority_assignment"]
      )

      User.transaction do
        applicants = []
        employees = []
        packages  = []
        users = []

        10.times do |i|
          user = User.create(name: "applicant user#{i}")
          users << user
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

        employee = Employee.all[0]
        employee.priority_assignment = employee.assignments.first

        expect(Employee.all[1].past_users).to eq([])
        expect(Employee.all[0].past_users).to contain_exactly(users[0], users[1], users[2])

        applicant = Applicant.all.first
        user = applicant.user

        expect(Applicant.that_owns(user)).to be(applicant)
        expect(Employee.that_owns(users[0], "past_")).to eq(Employee.all.first)
      end

      employee_id = nil
      assignment_id = nil

      User.transaction do
        expect(Employee.all[1].past_users).to eq([])
        # TODO: create .first query
        employee = Employee.all.first
        employee_id = employee.primary_key

        expect(employee.past_users).to contain_exactly(User.thunk(1), User.thunk(2), User.thunk(3))
        expect(employee.past_users).to eq(employee.values_at("past_assignments.#.package.applicants.#.user"))
        assignment_id = employee.past_assignments.first
        expect(
          Employee.find_by_attribute_containing(:past_assignments, employee.past_assignments.first)
        ).to be(employee)

        applicant = Applicant.all.first
        user = applicant.user

        expect(Applicant.that_owns(user)).to be(applicant)
        expect(Applicant.find_all_by_attribute_any_of(:user, user).to_a).to eq([applicant])
        expect(Employee.that_owns(User.thunk(1), "past_")).to eq(Employee.all.first)

        expect(employee.priority_package).to be_a(Package)
      end

      User.transaction do
        expect(
          Employee.find_by_attribute_containing(:past_assignments, assignment_id).primary_key
        ).to be(employee_id)
        expect(User.find_by_attribute(:name, "applicant user5")).to be(User.thunk(6))
      end
    end
  end
end
