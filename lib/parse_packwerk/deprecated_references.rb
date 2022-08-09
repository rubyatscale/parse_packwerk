# typed: strict

module ParsePackwerk
  class DeprecatedReferences < T::Struct
    extend T::Sig

    const :pathname, Pathname
    const :violations, T::Array[Violation]

    sig { params(package: Package).returns(DeprecatedReferences) }
    def self.for(package)
      deprecated_references_yml_pathname = package.directory.join(DEPRECATED_REFERENCES_YML_NAME)
      DeprecatedReferences.from(deprecated_references_yml_pathname)
    end

    sig { params(pathname: Pathname).returns(DeprecatedReferences) }
    def self.from(pathname)
      if !pathname.exist?
        new(
          pathname: pathname.cleanpath,
          violations: []
        )
      else
        deprecated_references_loaded_yml = YAML.load_file(pathname)

        all_violations = []
        deprecated_references_loaded_yml&.each_key do |to_package_name|
          deprecated_references_per_package = deprecated_references_loaded_yml[to_package_name]
          deprecated_references_per_package.each_key do |class_name|
            symbol_usage = deprecated_references_per_package[class_name]
            files = symbol_usage['files']
            violations = symbol_usage['violations']
            if violations.include? 'dependency'
              all_violations << Violation.new(type: 'dependency', to_package_name: to_package_name, class_name: class_name, files: files)
            end

            if violations.include? 'privacy'
              all_violations << Violation.new(type: 'privacy', to_package_name: to_package_name, class_name: class_name, files: files)
            end
          end
        end

        new(
          pathname: pathname.cleanpath,
          violations: all_violations
        )
      end
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_h
      {
        pathname: pathname,
        violations: violations.map(&:to_h)
      }
    end
  end
end
