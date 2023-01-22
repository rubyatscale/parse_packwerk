# typed: strict

module ParsePackwerk
  class Package < T::Struct
    extend T::Sig

    const :name, String
    const :enforce_dependencies, T.any(T::Boolean, String)
    const :enforce_privacy, T.any(T::Boolean, String)
    const :public_path, String, default: DEFAULT_PUBLIC_PATH
    const :metadata, MetadataYmlType
    const :dependencies, T::Array[String]
    const :config, T::Hash[T.untyped, T.untyped]

    sig { params(pathname: Pathname).returns(Package) }
    def self.from(pathname)
      package_loaded_yml = YAML.load_file(pathname)
      package_name = pathname.dirname.cleanpath.to_s

      new(
        name: package_name,
        enforce_dependencies: package_loaded_yml[ENFORCE_DEPENDENCIES],
        enforce_privacy: package_loaded_yml[ENFORCE_PRIVACY],
        public_path: package_loaded_yml[PUBLIC_PATH] || DEFAULT_PUBLIC_PATH,
        metadata: package_loaded_yml[METADATA] || {},
        dependencies: package_loaded_yml[DEPENDENCIES] || [],
        config: package_loaded_yml,
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

    sig { returns(Pathname) }
    def public_directory
      directory.join(public_path).cleanpath
    end

    sig { returns(T.any(T::Boolean, String)) }
    def enforces_dependencies?
      enforce_dependencies
    end

    sig { returns(T.any(T::Boolean, String)) }
    def enforces_privacy?
      enforce_privacy
    end

    sig { returns(T::Array[Violation]) }
    def violations
      PackageTodo.for(self).violations
    end

    # Returns all transitive dependencies using post-order depth first search, so all dependencies of a package appear
    # before the package. This does not preserve the order of direct dependencies if they depend on each other.
    sig { returns(T::Array[String]) }
    def transitive_dependencies
      @transitive_dependencies ||= T.let(nil, T.nilable(T::Array[String]))
      @transitive_dependencies ||= begin
        remaining = dependencies.dup
        result = T::Array[String].new
        while (dep = remaining.shift)
          dep_transitive_deps = ParsePackwerk.find(dep)&.transitive_dependencies || T::Array[String].new

          remaining -= dep_transitive_deps
          result |= dep_transitive_deps
          result << dep
        end
        result.freeze
      end
    end
  end
end
