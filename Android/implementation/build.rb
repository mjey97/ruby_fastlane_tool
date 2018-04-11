# build.rb / private_Lane :build
#==================================================================
# The private lane ':build' realized the gradle build process. All
# flavors given inside ENV['BETA_PRODUCT_FLAVORS'] will be created.
#==================================================================
# HINTS:
# ============================
# It's not possible to work with own build types.
# Everything can be handled with product flavors and dimensions.
# (dimensions e.g. ENV['BETA_PRODUCT_FLAVORS'] = 'dePro, frFree')
# See confluence for more informations about the usage of gradle here.
#==================================================================

#=================================================================#
#===================== HELPER METHODS ============================#
#=================================================================#

#------------------------------------------------------------------
# Raised an error if the following global variables aren't filled out.
# This should usually never happens, see it as a safety net.
#------------------------------------------------------------------
# GLOBAL GET ENV['EXCUTED_LANE']
#        GET ENV['VERSION_CODE']
#        GET ENV['VERSION_NAME']
#        GET ENV['FLAVORS']
#------------------------------------------------------------------
def checkEnvVariables
  laneName = lane_context[SharedValues::LANE_NAME]
  UI.user_error!("Internal error 'ENV['EXCUTED_LANE']' isn't filled out inside the private lane '#{laneName}'. Value is: '#{ENV['EXCUTED_LANE']}'.") if not ENV['EXCUTED_LANE']
  UI.user_error!("Internal error 'ENV['VERSION_CODE']' isn't filled out inside the private lane '#{laneName}'. Value is: '#{ENV['VERSION_CODE']}'.") if not ENV['VERSION_CODE']
  UI.user_error!("Internal error 'ENV['VERSION_NAME']' isn't filled out inside the private lane '#{laneName}'. Value is: '#{ENV['VERSION_NAME']}'.") if not ENV['VERSION_NAME']
  UI.user_error!("Internal error 'ENV['FLAVORS']' isn't filled out inside the private lane '#{laneName}'. Value is: '#{ENV['FLAVORS']}'.") if not ENV['FLAVORS']
end

#------------------------------------------------------------------
# Convert comma separated flavor variables from a string into an array.
#------------------------------------------------------------------
# IN:     flavors - all flavors as string
# RETURN: all flavors as array
#------------------------------------------------------------------
def getFlavorArr(flavors)
  return flavors.split(",").collect{ |x| x.strip || x }
end

#------------------------------------------------------------------
# Shows a upload header message for one build.
#------------------------------------------------------------------
# GLOBAL GET ENV['VERSION_CODE']
#        GET ENV['VERSION_NAME']
#------------------------------------------------------------------
# IN: flavor - one gradle flavor
#------------------------------------------------------------------
def showBuildInfo(flavor)
  UI.header "Next Built: \n            VersionCode: #{ENV['VERSION_CODE']} | VersionName: #{ENV['VERSION_NAME']}" +  " | Flavor: #{flavor}"  
end

#=================================================================#
#=============== START PRIVATE BUILD LANE ========================#
#=================================================================#
# ENVIRONMENT VARIABLES: (IN must be filled out from the caller)
# ============================
# IN:  ENV['EXCUTED_LANE']     - the lane where fastlane was started with (beta/release) 
# IN:  ENV['VERSION_CODE']     - the version code for the gradle builds
# IN:  ENV['VERSION_NAME']     - the version name for the gradle builds
# IN:  ENV['FLAVORS']          - all flavors of which an apk shall be build
# OUT: ENV['APP_OUTPUT_PATHS'] - all created apk paths as comma separated string
#=================================================================#

checkEnvVariables()

flavors = getFlavorArr(ENV['FLAVORS'])

gradle_properties = {
  'versionCodeProb' => ENV['VERSION_CODE'],
  'versionNameProb' => ENV['VERSION_NAME']
}

# deletes the build directory 
gradle(
  task: "clean"
)

# build process
flavors.each do |flavor|
  next if flavor.empty?

  showBuildInfo(flavor)
  gradle(
    task: 'assemble',
    flavor: flavor,
    build_type: 'Release',
    properties: gradle_properties
  )
end

# after build process
allApkOutputPaths = lane_context[SharedValues::GRADLE_ALL_APK_OUTPUT_PATHS]
UI.user_error!("Necessary environment variable isn't filled out correctly inside the Appfile.") if allApkOutputPaths.nil?

UI.header "Created the following apks:"
allApkOutputPaths.each do |apkOutput|
  UI.success apkOutput
  UI.error "Unsigned in apk name detected. The app is possibly not bootable. See confluence to fix it. (gradle structure)" if (apkOutput.include? "unsigned") 
  ENV['APP_OUTPUT_PATHS'] = (ENV['APP_OUTPUT_PATHS']) ? "#{ENV['APP_OUTPUT_PATHS']},#{apkOutput}" : apkOutput
end




