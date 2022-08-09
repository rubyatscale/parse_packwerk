# typed: strict

module ParsePackwerk
  class Package < T::Struct
    extend T::Sig

    const :name, String
    const :enforce_dependencies, T::Boolean
    const :enforce_privacy, T::Boolean
    const :metadata, MetadataYmlType
    const :dependencies, T::Array[String]

    sig { params(pathname: Pathname).returns(Package) }
    def self.from(pathname)
      package_loaded_yml = YAML.load_file(pathname)
      package_name = pathname.dirname.cleanpath.to_s

      new(
        name: package_name,
        enforce_dependencies: package_loaded_yml[ENFORCE_DEPENDENCIES] ? true : false,
        enforce_privacy: package_loaded_yml[ENFORCE_PRIVACY] ? true : false,
        metadata: package_loaded_yml[METADATA] || {},
        dependencies: package_loaded_yml[DEPENDENCIES] || []
      )
    end

    sig { returns(Pathname) }
    def yml
      Pathname.new(name).join(PACKAGE_YML_NAME).cleanpath
    end

    sig { returns(Pathname) }
    def directory
      Pathname.new(name).cleanpath
    end

    sig { returns(T::Boolean) }
    def enforces_dependencies?
      enforce_dependencies
    end

    sig { returns(T::Boolean) }
    def enforces_privacy?
      enforce_privacy
    end

    sig { returns(T::Array[Violation]) }
    def violations
      DeprecatedReferences.for(self).violations
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_h
      {
        name: name,
        enforce_dependencies: enforce_dependencies,
        enforce_privacy: enforce_privacy,
        metadata: metadata,
        dependencies: dependencies,
        violations: violations
      }
    end
  end
end
