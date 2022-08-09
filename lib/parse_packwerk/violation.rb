# typed: strict

module ParsePackwerk
  class Violation < T::Struct
    extend T::Sig

    const :type, String
    const :to_package_name, String
    const :class_name, String
    const :files, T::Array[String]

    sig { returns(T::Boolean) }
    def dependency?
      type == 'dependency'
    end

    sig { returns(T::Boolean) }
    def privacy?
      type == 'privacy'
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_h
      {
        type: type,
        package_name: to_package_name,
        class_name: class_name,
        files: files
      }
    end
  end
end
