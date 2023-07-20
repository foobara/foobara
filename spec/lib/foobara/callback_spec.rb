RSpec.describe Foobara::Callback do
  context "with single multiple action registry" do
    let(:registry) { Foobara::Callback::Registry::MultipleAction.new(:walk, :jump) }

    let(:calls) { {} }

    def called(action, type, data)
      for_type = calls[action] ||= {}
      data_array = for_type[type] ||= []
      data_array << data
    end

    before do
      %i[walk jump].each do |action|
        Foobara::Callback::Block.types.each do |type|
          basic_block = lambda { |foo|
            called(action, type, foo)
          }

          callback = if type == :around
                       lambda { |**opts, &do_it|
                         basic_block.call(opts)
                         do_it.call
                       }
                     else
                       basic_block
                     end

          registry.register_callback(type, action, &callback)
        end
      end
    end

    describe Foobara::Callback::Runner do
      let(:runner) { registry.runner(:walk).callback_data(foo: :bar) }

      describe "#run" do
        context "with block" do
          it "calls expected callbacks in order" do
            ran = false

            expect(calls).to eq({})

            registry.around(:walk) do |&do_it|
              expect(calls).to eq(
                walk: {
                  before: [{ foo: :bar }]
                }
              )

              do_it.call

              expect(calls).to eq(
                walk: {
                  before: [{ foo: :bar }],
                  around: [{ foo: :bar }]
                }
              )
            end

            expect {
              runner.run { ran = true }
            }.to change { ran }.from(false).to(true)

            expect(calls).to eq(
              walk: {
                before: [{ foo: :bar }],
                around: [{ foo: :bar }],
                after: [{ foo: :bar }]
              }
            )
          end
        end

        context "with any action callback" do
          before do
            registry.before(nil) do
              called(nil, :before, :any_called)
            end
          end

          it "calls the any callback on any action" do
            runner1 = registry.runner(:walk).callback_data(foo: :w)
            runner2 = registry.runner(:jump).callback_data(foo: :j)

            runner1.run do
              # empty block
            end
            runner2.run do
              # empty block
            end

            expect(calls).to eq(
              {
                nil => {
                  before: %i[any_called any_called]
                },
                walk: {
                  before: [{ foo: :w }],
                  around: [{ foo: :w }],
                  after: [{ foo: :w }]
                },
                jump: {
                  before: [{ foo: :j }],
                  around: [{ foo: :j }],
                  after: [{ foo: :j }]
                }
              }
            )
          end
        end

        context "when error occurs" do
          let(:kaboom) { Class.new(StandardError) }

          it "calls the any callback on any action" do
            expect {
              runner.run do
                raise kaboom, "Kaboom!"
              end
            }.to raise_error(kaboom)

            puts calls

            expect(calls.keys).to eq([:walk])
            walk = calls[:walk]
            expect(walk.keys).to eq(%i[before around error])

            expect(walk[:before]).to eq([{ foo: :bar }])
            expect(walk[:around]).to eq([{ foo: :bar }])
            errors = walk[:error]

            expect(errors.length).to eq(1)
            error = errors.first

            expect(error).to be_a(runner.class::UnexpectedErrorWhileRunningCallback)
            expect(error.cause).to be_a(kaboom)
            expect(error.callback_data).to eq(foo: :bar)
            expect(error.message).to eq("Kaboom!")
            expect(error.cause).to be_a(kaboom)
            expect(error.cause.message).to eq("Kaboom!")
          end
        end
      end
    end
  end
end
