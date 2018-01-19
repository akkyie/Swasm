#!/usr/bin/env ruby

require 'xcodeproj'

project_path = File.expand_path('../../Swasm.xcodeproj', __FILE__)
project = Xcodeproj::Project.open(project_path)

PHASE_NAME = "Run SwiftFormat"

project.targets.each do |target|
  next if target.build_phases.any? do |phase|
    phase.respond_to?(:name) and phase.name == PHASE_NAME
  end

  next unless target.name.include? "Test"

  phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
  phase.name = PHASE_NAME
  phase.shell_script = <<-EOS
  if which swiftformat >/dev/null; then
    swiftformat Package.swift "${SRCROOT}/Sources" "${SRCROOT}/Tests"
  else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
  EOS

  target.build_phases.unshift(phase)
end

project.save()

puts "Added a build phase named \"#{PHASE_NAME}\""
