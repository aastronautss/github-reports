module Reports
  module Storage
    class Memory
      def initialize(hash = {})
        @hash = hash
      end

      def read(key)
        Marshal.load(@hash[key]) if @hash[key]
      end

      def write(key, value)
        @hash[key] = Marshal.dump(value)
      end
    end
  end
end
