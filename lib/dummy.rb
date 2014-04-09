# Dummy Strategy for Capistrano 3

load File.expand_path("../dummy.rake", __FILE__)
require 'capistrano/scm'
require 'capistrano/dsl'

module Capistrano::DSL::Paths
  def set_release_path(_ = nil)
    set(:release_path, repo_path)
  end
end

class Capistrano::Dummy < Capistrano::SCM
  module DefaultStrategy
    def test
      true
    end

    def check
      true
    end

    def clone
      true
    end

    def update
      true
    end

    def release
      true
    end
  end
end
