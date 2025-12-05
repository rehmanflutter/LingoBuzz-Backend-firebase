#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Runner target
runner_target = project.targets.find { |t| t.name == 'Runner' }
widget_target = project.targets.find { |t| t.name == 'MyHomeWidgetExtension' }

if runner_target
  puts "✅ Found Runner target"

  # Add entitlements file reference if not exists
  entitlements_ref = project.files.find { |f| f.path == 'Runner/Runner.entitlements' }

  if !entitlements_ref
    entitlements_ref = project.new_file('Runner/Runner.entitlements')
    puts "✅ Added Runner.entitlements file reference"
  end

  # Set CODE_SIGN_ENTITLEMENTS for all configurations
  runner_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
    puts "✅ Set CODE_SIGN_ENTITLEMENTS for #{config.name}"
  end
else
  puts "❌ Runner target not found"
end

if widget_target
  puts "✅ Found MyHomeWidgetExtension target"

  # Add entitlements file reference if not exists
  widget_entitlements_ref = project.files.find { |f| f.path == 'MyHomeWidget/MyHomeWidgetExtension.entitlements' }

  if !widget_entitlements_ref
    widget_entitlements_ref = project.new_file('MyHomeWidget/MyHomeWidgetExtension.entitlements')
    puts "✅ Added MyHomeWidgetExtension.entitlements file reference"
  end

  # Set CODE_SIGN_ENTITLEMENTS for all configurations
  widget_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'MyHomeWidget/MyHomeWidgetExtension.entitlements'
    puts "✅ Set CODE_SIGN_ENTITLEMENTS for widget #{config.name}"
  end
else
  puts "❌ MyHomeWidgetExtension target not found"
end

# Save the project
project.save
puts "✅ Project saved successfully"
