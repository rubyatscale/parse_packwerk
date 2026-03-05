This file provides guidance to AI coding agents when working with code in this repository.

## What this project is

`parse_packwerk` is a low-dependency Ruby gem for parsing and writing the YAML files that packwerk uses: `package.yml` (package config) and `package_todo.yml` (recorded violations).

## Commands

```bash
bundle install

# Run all tests (RSpec)
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/path/to/spec.rb

# Lint
bundle exec rubocop
bundle exec rubocop -a  # auto-correct

# Type checking (Sorbet)
bundle exec srb tc
```

## Architecture

- `lib/parse_packwerk.rb` — entry point; `ParsePackwerk.all` returns all packages
- `lib/parse_packwerk/` — `Package` (parses `package.yml`), `PackageTodo` (parses `package_todo.yml`), and YAML write-back helpers that preserve comments and ordering
- `spec/` — RSpec tests
