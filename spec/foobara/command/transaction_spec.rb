RSpec.describe Foobara::Command::Concerns::Entities do
  describe "#run" do
    after do
      Foobara.reset_alls
    end

    let(:user_base) do
      Foobara::Persistence::EntityBase.new(
        "user_base",
        entity_attributes_crud_driver: Foobara::Persistence::CrudDrivers::InMemory.new
      ).tap do |base|
        Foobara::Persistence.register_base(base)
      end
    end

    let(:read_command) do
      stub_class = ->(klass) { stub_const(klass.name, klass) }

      Class.new(Foobara::Command) do
        class << self
          def name
            "ReadEmployee"
          end
        end

        stub_class.call(self)

        # TODO: does this work with Employee instead of :Employee ?
        inputs employee: { type: :Employee, required: true }

        load_all

        result Employee

        def execute
          employee
        end
      end
    end

    let(:employee_id) do
      Foobara::Persistence.transaction(Employee, User, mode: :use_existing) do
        Employee.all[0].id
      end
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

      Foobara::Persistence.register_entity(user_base, User)

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

      # TODO: how to support self-referential models??
      Class.new(Person) do
        class << self
          def name
            "Applicant"
          end
        end

        stub_class.call(self)

        attributes is_active: { type: :boolean, default: true },
                   friends: [User],
                   attrs: {
                     foo: :symbol,
                     bar: [:integer],
                     duckfoo: :duck,
                     duckbar: [:duck]
                   }
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

      applicant_users = []
      employee_users = []

      User.transaction do
        5.times do |i|
          applicant_users << User.create(name: "applicant user#{i}")
        end

        5.times do |i|
          employee_users << User.create(name: "employee user#{i}")
        end
      end

      Foobara::Persistence.transaction(Employee, User) do
        applicants = []
        employees = []

        5.times do |i|
          applicants << Applicant.create(user: applicant_users[i])
        end

        5.times do |i|
          employees << Employee.create(user: employee_users[i])
        end

        7.times do |i|
          package = Package.create(is_active: i < 3, applicants: [applicants[i % 3]])

          assignment = Assignment.create(package:)

          if i < 5
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

    it "can find the record" do
      expect(read_command.run!(employee: employee_id).id).to eq(employee_id)
    end

    context "with multiple records" do
      let(:read_command) do
        stub_class = ->(klass) { stub_const(klass.name, klass) }

        Class.new(Foobara::Command) do
          class << self
            def name
              "ReadEmployee"
            end
          end

          stub_class.call(self)

          # TODO: does this work with Employee instead of :Employee ?
          inputs employee: { type: :Employee, required: true },
                 employee_array: [Employee]

          load_all

          result [Employee]

          def execute
            [employee, *employee_array]
          end
        end
      end

      let!(:employee2_id) do
        Employee.transaction do
          Employee.create
        end.id
      end

      let!(:employee3_id) do
        Employee.transaction do
          Employee.create
        end.id
      end

      it "can find the records" do
        inputs = { employee: employee_id, employee_array: [employee2_id, employee3_id] }
        expect(read_command.run!(inputs).map(&:id)).to eq([employee_id, employee2_id, employee3_id])
      end
    end

    context "when given primary key for record that doesnt exist" do
      it "is not success" do
        outcome = read_command.run(employee: 100)
        expect(outcome).to_not be_success

        errors = outcome.errors

        expect(errors.size).to eq(1)

        error = errors.first

        expect(error.class.name).to eq("ReadEmployee::EmployeeNotFoundError")
        expect(error.key).to eq("runtime.employee_not_found")

        expect(error.symbol).to be(:employee_not_found)

        context = error.context

        expect(context[:entity_class]).to eq("Employee")
        expect(context[:primary_key]).to eq(100)
        expect(context[:data_path]).to eq("employee")
      end
    end

    context "when given non-castable primary key" do
      it "is not success" do
        outcome = read_command.run(employee: "asdf")
        expect(outcome).to_not be_success

        errors = outcome.errors

        expect(errors.size).to eq(1)

        error = errors.first

        expect(error.key).to eq("data.employee.cannot_cast")
      end
    end

    context "when input is good but a different runtime error occurs" do
      let(:read_command) do
        stub_class = ->(klass) { stub_const(klass.name, klass) }

        error_class = Class.new(Foobara::RuntimeError) do
          class << self
            def name
              "SomeRuntimeError"
            end

            def context_type_declaration
              {}
            end
          end

          stub_class.call(self)
        end

        Class.new(Foobara::Command) do
          class << self
            def name
              "ReadEmployee"
            end
          end

          stub_class.call(self)

          # TODO: does this work with Employee instead of :Employee ?
          inputs employee: { type: :Employee, required: true }

          load_all

          possible_error error_class

          result Employee

          define_method :execute do
            employee.assignments = []
            add_runtime_error(error_class.new(message: "asdf", context: {}))
          end
        end
      end

      it "is not success and rolls back" do
        old_assignments = Foobara::Persistence.transaction(Employee, User, mode: :use_existing) do
          Employee.load(employee_id).assignments
        end

        expect(old_assignments).to_not be_empty

        outcome = read_command.run(employee: employee_id)
        expect(outcome).to_not be_success

        errors = outcome.errors

        expect(errors.size).to eq(1)

        error = errors.first

        expect(error.class.name).to eq("SomeRuntimeError")

        Foobara::Persistence.transaction(Employee, User, mode: :use_existing) do
          expect(Employee.load(employee_id).assignments).to eq(old_assignments)
        end
      end
    end

    describe "manifest" do
      it "includes entity dependencies" do
        expect(Foobara.manifest[:global_organization][:global_domain][:types][:Employee][:deep_depends_on]).to eq(
          %w[
            Assignment
            User
            Package
            Applicant
          ]
        )
      end
    end

    describe "create command" do
      context "with entity class as inputs" do
        let(:create_command) do
          stub_class = ->(klass) { stub_const(klass.name, klass) }

          Class.new(Foobara::Command) do
            class << self
              def name
                "CreateUser"
              end
            end

            stub_class.call(self)

            # TODO: does this work with User instead of :User ?
            # We can't come up with a cleaner way to do this?
            inputs User.attributes_type.declaration_data
            result User

            # TODO: automatically include result type if it's an entity to avoid this in such cases
            depends_on_entities User

            def execute
              create_user

              user
            end

            attr_accessor :user

            def create_user
              self.user = User.create(inputs)
            end
          end
        end

        it "can create an user" do
          command = create_command.new(name: "Some Name")
          outcome = command.run

          expect(outcome).to be_success
          expect(command.user).to be_a(User)

          result = outcome.result
          expect(result.name).to eq("Some Name")
          expect(result.id).to be_a(Integer)
        end
      end

      context "with normal attributes inputs" do
        let(:create_command) do
          stub_class = ->(klass) { stub_const(klass.name, klass) }

          Class.new(Foobara::Command) do
            class << self
              def name
                "CreateUser"
              end
            end

            stub_class.call(self)

            # TODO: does this work with User instead of :User ?
            # We can't come up with a cleaner way to do this?
            inputs user: User
            result User

            def execute
              user
            end
          end
        end

        it "can create an user" do
          command = create_command.new(user: { name: "Some Name" })
          outcome = Foobara::Persistence.transaction(Employee, User, mode: :use_existing) do
            command.run
          end
          expect(outcome).to be_success
          expect(command.user).to be_a(User)

          result = outcome.result
          expect(result.name).to eq("Some Name")
          expect(result.id).to be_a(Integer)
        end
      end
    end

    describe "update atom command" do
      context "with helper method result for inputs" do
        let(:update_command) do
          stub_class = ->(klass) { stub_const(klass.name, klass) }

          Class.new(Foobara::Command) do
            class << self
              def name
                "UpdateApplicant"
              end
            end

            stub_class.call(self)

            # TODO: does this work with User instead of :User ?
            # We can't come up with a cleaner way to do this?
            inputs Foobara::Command::EntityHelpers.type_declaration_for_record_atom_update(Applicant)
            result Applicant # seems like we should just use nil?

            def execute
              update_applicant

              applicant
            end

            attr_accessor :applicant

            def load_records
              self.applicant = Applicant.load(id)
            end

            def update_applicant
              inputs.each_pair do |attribute_name, value|
                applicant.write_attribute(attribute_name, value)
              end
            end
          end
        end

        let(:applicant) { Applicant.create(user:, is_active: true) }
        let(:user) { User.create(name: "first user") }

        it "can update an applicant" do
          applicant_id = Applicant.transaction { applicant }.id

          Applicant.transaction do
            expect {
              update_command.run!(id: applicant_id, is_active: false)
            }.to change { Applicant.load(applicant_id).is_active }.from(true).to(false)

            expect {
              update_command.run!(id: applicant_id, is_active: true)
            }.to change { Applicant.load(applicant_id).is_active }.from(false).to(true)
          end

          new_user_id = User.transaction(skip_dependent_transactions: true) { User.create(name: "second user") }.id

          Applicant.transaction do
            expect {
              update_command.run!(id: applicant_id, user: new_user_id)
            }.to change { Applicant.load(applicant_id).user.name }.from("first user").to("second user")
          end
        end
      end
    end

    describe "update aggregate command" do
      context "with helper method result for inputs" do
        let(:update_command) do
          stub_class = ->(klass) { stub_const(klass.name, klass) }

          Class.new(Foobara::Command) do
            class << self
              def name
                "UpdateApplicantAggregate"
              end
            end

            stub_class.call(self)

            # TODO: does this work with User instead of :User ?
            # We can't come up with a cleaner way to do this?
            inputs Foobara::Command::EntityHelpers.type_declaration_for_record_aggregate_update(Applicant)
            result Applicant # seems like we should just use nil?

            def execute
              update_applicant

              applicant
            end

            attr_accessor :applicant

            def load_records
              self.applicant = Applicant.load(id)
            end

            def update_applicant
              Foobara::Command::EntityHelpers.update_aggregate(applicant, inputs)
            end
          end
        end

        let(:applicant) do
          Applicant.create(
            user:,
            is_active: true,
            attrs: {
              foo: :fooooo,
              bar: [1, 2, 3, 4],
              duckfoo: "asdfasdf",
              duckbar: ["asdf", 5]
            }
          )
        end
        let(:user) { User.create(name: "old name") }

        it "can update an applicant" do
          applicant_id = Applicant.transaction { applicant }.id
          user_id = User.transaction { user }.id

          Applicant.transaction do
            expect {
              update_command.run!(id: applicant_id, is_active: false)
            }.to change { Applicant.load(applicant_id).is_active }.from(true).to(false)

            expect {
              update_command.run!(id: applicant_id, is_active: true)
            }.to change { Applicant.load(applicant_id).is_active }.from(false).to(true)
          end

          Applicant.transaction do
            update_command.run!(
              id: applicant_id,
              user: { name: "new name" },
              attrs: {
                foo: :food,
                bar: [10, 11],
                duckfoo: "df",
                duckbar: %w[db asdf]
              }
            )
          end

          Applicant.transaction do
            applicant = Applicant.load(applicant_id)
            expect(applicant.user.name).to eq("new name")
            expect(applicant.user.id).to eq(user_id)
            expect(applicant.attrs).to eq(
              foo: :food,
              bar: [10, 11],
              duckfoo: "df",
              duckbar: %w[db asdf]
            )
          end
        end
      end
    end

    describe "delete command" do
      let(:delete_command) do
        stub_class = ->(klass) { stub_const(klass.name, klass) }

        Class.new(Foobara::Command) do
          class << self
            def name
              "DeleteApplicant"
            end
          end

          stub_class.call(self)

          # TODO: does this work with User instead of :User ?
          # We can't come up with a cleaner way to do this?
          inputs applicant: Applicant
          result Applicant

          load_all

          def execute
            delete_applicant

            applicant
          end

          def delete_applicant
            applicant.hard_delete!
          end
        end
      end

      let(:applicant) { Applicant.create(user:) }
      let(:user) { User.create(name: "old name") }

      it "deletes the applicant" do
        applicant_id = Applicant.transaction { applicant }.id

        Applicant.transaction do
          expect {
            delete_command.run!(applicant: applicant_id)
          }.to change(Applicant, :count).by(-1)
        end

        Applicant.transaction do
          expect {
            Applicant.load(applicant_id)
          }.to raise_error(Foobara::Persistence::EntityAttributesCrudDriver::Table::CannotFindError)
        end
      end
    end
  end
end
