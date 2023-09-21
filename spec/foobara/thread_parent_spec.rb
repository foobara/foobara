RSpec.describe Foobara::ThreadParent do
  describe "#foobara_var_set and #foobara_var_get" do
    it "inherits from parent threads and overrides locally" do
      outer = Thread.new do
        Thread.foobara_var_set("test", "outer")
        expect(Thread.foobara_var_get("test")).to eq("outer")

        inner = Thread.new do
          expect(Thread.foobara_var_get("test")).to eq("outer")
          Thread.foobara_var_set("test", "inner")
          expect(Thread.foobara_var_get("test")).to eq("inner")
        end

        sleep 0.2
        expect(Thread.foobara_var_get("test")).to eq("outer")
        inner.join
        expect(Thread.foobara_var_get("test")).to eq("outer")
        expect(inner.foobara_var_get("test")).to eq("inner")
      end

      expect(Thread.foobara_var_get("test")).to be_nil
      outer.join
      expect(Thread.foobara_var_get("test")).to be_nil
    end
  end
end
