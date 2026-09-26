# typed: strict
# frozen_string_literal: true

module ParsePackwerk
  ROOT_PACKAGE_NAME = T.let('.', String)
  PACKAGE_YML_NAME = T.let('package.yml', String)
  PACKWERK_YML_NAME = T.let('packwerk.yml', String)
  PACKAGE_TODO_YML_NAME = T.let('package_todo.yml', String)
  ENFORCE_DEPENDENCIES = T.let('enforce_dependencies', String)
  ENFORCE_PRIVACY = T.let('enforce_privacy', String)
  ENFORCE_LAYERS = T.let('enforce_layers', String)
  DEPENDENCY_VIOLATION_TYPE = T.let('dependency', String)
  PRIVACY_VIOLATION_TYPE = T.let('privacy', String)
  PUBLIC_PATH = T.let('public_path', String)
  METADATA = T.let('metadata', String)
  DEPENDENCIES = T.let('dependencies', String)

  # Since this metadata is unstructured YAML, it could be any type. We leave it to clients of `ParsePackwerk::Package`
  # to add types based on their known usage of metadata.
  MetadataYmlType = T.type_alias do
    T::Hash[T.untyped, T.untyped]
  end

  DEFAULT_EXCLUDE_GLOBS = T.let(['{bin,node_modules,script,tmp,vendor}/**/*'], T::Array[String])
  DEFAULT_PACKAGE_PATHS = T.let(['**/'], T::Array[String])
  DEFAULT_PUBLIC_PATH = T.let('app/public', String)
end
