platform :ios, '16.0'

target 'SeeSaw' do
  use_frameworks!
  pod 'MediaPipeTasksGenAI'

  target 'SeeSawTests' do
    inherit! :search_paths
  end

  target 'SeeSawUITests' do
    inherit! :search_paths
  end
end

# Strip -force_load of the MediaPipe static lib from test target xcconfigs.
# Test bundles run inside the host app process which already has the static lib
# loaded. Re-linking it into the test bundle causes duplicate ObjC class
# registration and a FunctionRegistry CHECK-fail crash at test startup.
# The FRAMEWORK_SEARCH_PATHS inherited via :search_paths are still present so
# the Swift compiler can resolve the MediaPipeTasksGenAI module dependency that
# SeeSaw.swiftmodule records, without actually re-linking the .a.
post_install do |installer|
  test_pod_targets = %w[Pods-SeeSawTests Pods-SeeSawUITests]
  test_pod_targets.each do |target_name|
    %w[debug release].each do |config_name|
      xcconfig_path = File.join(
        installer.config.installation_root,
        'Pods', 'Target Support Files', target_name,
        "#{target_name}.#{config_name}.xcconfig"
      )
      next unless File.exist?(xcconfig_path)
      content = File.read(xcconfig_path)
      # Remove the sdk-conditional OTHER_LDFLAGS lines that contain -force_load
      content = content.gsub(/^OTHER_LDFLAGS\[sdk=(?:iphoneos|iphonesimulator)\*\].*-force_load.*\n/, '')
      File.write(xcconfig_path, content)
    end
  end
end
