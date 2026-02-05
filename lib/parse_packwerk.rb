# typed: strict

require 'sorbet-runtime'
require 'yaml'
require 'pathname'

# fileutils is loaded by a development gem dependency, but requiring here so clients
# do not get `uninitialized constant ParsePackwerk::FileUtils`
require 'fileutils'

require 'parse_packwerk/constants'
require 'parse_packwerk/violation'
require 'parse_packwerk/package_todo'
require 'parse_packwerk/package'
require 'parse_packwerk/configuration'
require 'parse_packwerk/package_set'
require 'parse_packwerk/extensions'

module ParsePackwerk
  class PackageParseError < StandardError
  end

  class MissingConfiguration < StandardError
    extend T::Sig

    sig { params(packwerk_file_name: Pathname).void }
    def initialize(packwerk_file_name)
      super("We could not find a configuration file at #{packwerk_file_name}")
    end
  end

  extend T::Sig

  # Configuration option to preserve the original key order when writing package.yml files.
  # When true, keys will be written in their original order from the file rather than
  # being sorted according to key_sort_order. This reduces diff churn when tools modify packages.
  # Defaults to false for backwards compatibility.
  @preserve_key_order = T.let(false, T::Boolean)

  class << self
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_accessor :preserve_key_order
  end

  sig do
    returns(T::Array[Package])
  end
  def self.all
    packages_by_name.values
  end

  sig { params(name: String).returns(T.nilable(Package)) }
  def self.find(name)
    packages_by_name[name]
  end

  sig { returns(ParsePackwerk::Configuration) }
  def self.yml
    Configuration.fetch
  end

  sig { params(file_path: T.any(Pathname, String)).returns(Package) }
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
      merged_config = package.config

      merged_config.merge!('enforce_dependencies' => package.enforce_dependencies)

      if Extensions.privacy_extension_installed?
        merged_config.merge!('enforce_privacy' => package.enforce_privacy)
      end

      if Extensions.layer_extension_installed?
        merged_config.merge!('enforce_layers' => package.enforce_layers)
      end

      unless package.public_path == DEFAULT_PUBLIC_PATH
        merged_config.merge!('public_path' => package.public_path)
      end

      if package.dependencies.nil? || package.dependencies.none?
        merged_config.delete('dependencies')
      else
        merged_config.merge!('dependencies' => package.dependencies)
      end

      if package.metadata.any?
        merged_config.merge!('metadata' => package.metadata)
      end

      merged_config = sort_keys(merged_config, package.original_key_order)

      raw_yaml = YAML.dump(merged_config)
      stylized_yaml = raw_yaml.gsub("---\n", '')
      file.write(stylized_yaml)
    end
  end

  sig { params(config: T::Hash[T.untyped, T.untyped], original_key_order: T::Array[String]).returns(T::Hash[T.untyped, T.untyped]) }
  def self.sort_keys(config, original_key_order)
    if preserve_key_order && original_key_order.any?
      # Preserve original key order: existing keys stay in their original position,
      # new keys are appended in the default sort order
      existing_keys = original_key_order & config.keys
      new_keys = config.keys - original_key_order
      sorted_new_keys = new_keys.sort_by { |key| key_sort_order.index(key) || 1000 }

      ordered_keys = existing_keys + sorted_new_keys
      ordered_keys.each_with_object({}) { |key, hash| hash[key] = config[key] if config.key?(key) }
    else
      # Default behavior: sort by canonical key order
      config.to_a.sort_by { |key, _value| T.unsafe(key_sort_order).index(key) || 1000 }.to_h
    end
  end

  sig { returns(T::Array[String]) }
  def self.key_sort_order
    %w[
      enforce_dependencies
      enforce_privacy
      enforce_visibility
      enforce_layers
      public_path
      owner
      layer
      dependencies
      ignored_dependencies
      visible_to
      metadata
    ]
  end

  # We memoize packages_by_name for fast lookup.
  # Since Graph is an immutable value object, we can create indexes and general caching mechanisms safely.
  sig { returns(T::Hash[String, Package]) }
  def self.packages_by_name
    @packages_by_name = T.let(@packages_by_name, T.nilable(T::Hash[String, Package]))
    @packages_by_name ||= begin
      all_packages = PackageSet.from(package_pathspec: yml.package_paths, exclude_pathspec: yml.exclude)
      # We want to match more specific paths first
      # Packwerk does this too and is necessary for package_from_path to work correctly.
      sorted_packages = all_packages.sort_by { |package| -package.name.length }
      sorted_packages.to_h { |p| [p.name, p] }
    end
  end

  sig { void }
  def self.bust_cache!
    @packages_by_name = nil
    @package_from_path = nil
  end

  private_class_method :packages_by_name
end
