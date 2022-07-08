# typed: strict

require 'sorbet-runtime'
require 'yaml'
require 'pathname'
require 'parse_packwerk/constants'
require 'parse_packwerk/violation'
require 'parse_packwerk/deprecated_references'
require 'parse_packwerk/package'
require 'parse_packwerk/configuration'
require 'parse_packwerk/package_set'

module ParsePackwerk
  class MissingConfiguration < StandardError
    extend T::Sig

    sig { params(packwerk_file_name: Pathname).void }
    def initialize(packwerk_file_name)
      super("We could not find a configuration file at #{packwerk_file_name}")
    end
  end

  extend T::Sig

  sig do
    returns(T::Array[Package])
  end
  def self.all
    PackageSet.from(package_pathspec: yml.package_paths, exclude_pathspec: yml.exclude)
  end

  sig { params(name: String).returns(T.nilable(Package)) }
  def self.find(name)
    packages_by_name[name]
  end

  sig { returns(ParsePackwerk::Configuration) }
  def self.yml
    Configuration.fetch
  end

  sig { params(file_path: T.any(Pathname, String)).returns(T.nilable(Package)) }
  def self.package_from_path(file_path)
    path_string = file_path.to_s
    @package_from_path = T.let(@package_from_path, T.nilable(T::Hash[String, Package]))
    @package_from_path ||= {}
    @package_from_path[path_string] ||= T.must(begin
      matching_package = all.find { |package| path_string.start_with?("#{package.name}/") || path_string == package.name }
      matching_package || find(ROOT_PACKAGE_NAME)
    end)
  end

  sig { params(package: ParsePackwerk::Package).void }
  def self.write_package_yml!(package)
    FileUtils.mkdir_p(package.directory)
    File.open(package.yml, 'w') do |file|
      # We do not use `YAML.dump` or `contents.to_yaml` because it seems like packwerk writes a variation of the default YAML spec.
      # If you'd like to see the difference, change this to `package_yaml = YAML.dump(contents)` to and run tests to see the difference.
      package_yml = <<~PACKAGEYML
        enforce_dependencies: #{package.enforces_dependencies?}
        enforce_privacy: #{package.enforces_privacy?}
      PACKAGEYML

      if package.dependencies.any?
        dependencies = <<~STATEDDEPS
          dependencies:
          #{package.dependencies.map { |dep| "  - #{dep}" }.join("\n")}
        STATEDDEPS

        package_yml += dependencies
      end

      if package.metadata.keys.any?
        raw_yaml = YAML.dump(package.metadata)
        stylized_yaml = raw_yaml.gsub("---\n", '')
        indented_yaml = stylized_yaml.split("\n").map { |line| "  #{line}" }.join("\n")

        metadata = <<~METADATA
          metadata:
          #{indented_yaml}
        METADATA

        package_yml += metadata
      end

      file.write(package_yml)
    end
  end

  # We memoize packages_by_name for fast lookup.
  # Since Graph is an immutable value object, we can create indexes and general caching mechanisms safely.
  sig { returns(T::Hash[String, Package]) }
  def self.packages_by_name
    @packages_by_name = T.let(@packages_by_name, T.nilable(T::Hash[String, Package]))
    @packages_by_name ||= begin
      all.map{|p| [p.name, p]}.to_h
    end
  end

  private_class_method :packages_by_name
end
