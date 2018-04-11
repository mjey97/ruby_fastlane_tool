# playstore.rb / public lane :release
#=================================================================#
# The public lane ':release' realized the android app distribution
# and upload to Google PlayStore.
#=================================================================#

#=================================================================#
#===================== HELPER METHODS ============================#
#=================================================================#

#------------------------------------------------------------------
# Returns a 2 dimensional array from the global environment variable. 
#------------------------------------------------------------------
# GLOBAL GET ENV['RELEASE_PRODUCT_FLAVORS_WITH_JSON']
#------------------------------------------------------------------
# RETURN: a 2 dimensional array [flavor][json_file_path]
#------------------------------------------------------------------
def getMulDimArrFromFlavorJson
  str = ENV['RELEASE_PRODUCT_FLAVORS_WITH_JSON']
  arr = str.tr("\n","").strip.split(/[,|:]/m)
  bigArr = []
  arr.each_with_index { | x, index| arr[index] = x.strip }

  UI.user_error!("ENV['RELEASE_PRODUCT_FLAVORS_WITH_JSON'] isn't valid. Use a double point as separator between a flavor and json pair.") if arr.count.odd?
  
  single = 0
  pair = 0
  while single < (arr.count)
    if single.even?
      bigArr += [[]]
      bigArr[pair][0] = arr[single]
    else
      bigArr[pair][1] = arr[single]
      pair += 1
    end
    single += 1
  end 
  return bigArr
end

#------------------------------------------------------------------
# Returns all flavors form the two dimensional array as string.
#------------------------------------------------------------------
# IN:    flavorJsonArr  - the two dimensional array from  the
#                         'getMulDimArrFromFlavorJson' method
# RETURN: all flavors as string, comma separated
#------------------------------------------------------------------
def getAllFlavorsFrom2DimArr(flavorJsonArr)
  flavorsStr = ""
  flavorJsonArr.each_with_index  do  | arr2Dim, index  | 
    flavorsStr += flavorsStr.empty? ? "#{arr2Dim[0]}" : ", #{arr2Dim[0]}"
  end
  return flavorsStr
end

#------------------------------------------------------------------
# Check if all necessary environment variables were filled out.
#------------------------------------------------------------------
# GLOBAL GET ENV['PACKAGE_NAME']
#        GET ENV['RELEASE_PRODUCT_FLAVORS_WITH_JSON']
#------------------------------------------------------------------
def checkIfEnvFilled
  env = ENV['PACKAGE_NAME']
  UI.user_error!("'ENV['PACKAGE_NAME']' isn't filled out.") if (env.nil? || env.empty?)
  env = ENV['RELEASE_PRODUCT_FLAVORS_WITH_JSON']
  UI.user_error!("'ENV['RELEASE_PRODUCT_FLAVORS_WITH_JSON']' isn't filled out.") if (env.nil? || env.empty?)
end

#------------------------------------------------------------------
# Returns the version name from the last git tag, which is needed 
# for the build process afterwards.
#------------------------------------------------------------------
# IN:     lastGitTag - the last git tag, which includes the version number
# RETURN: the version name for the build process
#------------------------------------------------------------------
def getCheckedVersionName(lastGitTag)
  versionName = lastGitTag
  UI.user_error!("The tag name '#{lastGitTag}' isn't matching the right syntax. (major.minor.patch)") if (not (versionName =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}$/))
  return versionName
end

#------------------------------------------------------------------
# Shows a upload header message for one build.
#------------------------------------------------------------------
# GLOBAL GET ENV['VERSION_CODE']
#        GET ENV['VERSION_NAME']
#        GET ENV['BETA_PRODUCT_FLAVORS']
#------------------------------------------------------------------
# IN: flavor   - the gradle flavor
# IN: jsonFile - the signing json file for this app
#------------------------------------------------------------------
def showUploadMessage(flavor, jsonFile)
  UI.header "Next Google PlayStore upload: \n            VersionCode: #{ENV['VERSION_CODE']} | VersionName: #{ENV['VERSION_NAME']} | Flavor: #{flavor} | JSON signing file: #{jsonFile}"
end

#=================================================================#
#================== START RELEASE LANE ===========================#
#=================================================================#

#====================== BEFORE START =============================#
  
ENV['EXCUTED_LANE'] = 'release'

# https://docs.fastlane.tools/actions/#ensure_git_status_clean
ensure_git_status_clean

checkIfEnvFilled()

# Release uploads can only be launched on the master branch.
# If git is not on the master branch an exception will be triggert here.
ensure_git_branch

#=========================== START ===============================#

#-------------- GET VERSION_CODE AND VERSION_NAME ----------------#

ENV['VERSION_NAME'] = getCheckedVersionName(last_git_tag)
ENV['VERSION_CODE'] = getCheckedVersionCode()

UI.message "VersionName: " + ENV['VERSION_NAME']
UI.message "VersionCode: " + ENV['VERSION_CODE']

#--------------------------- BUILD -------------------------------#

flavorJsonArr = getMulDimArrFromFlavorJson()

ENV['FLAVORS'] = getAllFlavorsFrom2DimArr(flavorJsonArr)

# start private lane :build
# All global environment variable for the build lane are already filled.
build()

#------------------------ Google PlayStore -----------------------#

# https://docs.fastlane.tools/actions/#supply
# pacakge_name is the same for each app build

ENV['APP_OUTPUT_PATHS'].split(',').each_with_index do |apkOutput, index|
  showUploadMessage(flavorJsonArr[index][0], flavorJsonArr[index][1])
  supply(
    package_name: ENV['PACKAGE_NAME'],
    track: 'production',
    json_key: "certificates/#{flavorJsonArr[index][1]}",
    apk: apkOutput,
    validate_only: false,
    skip_upload_apk: false,
    skip_upload_metadata: true,
    skip_upload_images: true,
    skip_upload_screenshots: true 
  )
end

#---------------------------- SLACK -------------------------------#

repoName = getRepoName() 
begin     
  slack(
    message: "Repo: " + ((repoName) ? "#{repoName}" : "Couldn't abstract from git\n") + "Flavors: #{ENV['FLAVORS']}\nVersion Name: #{ENV['VERSION_NAME']} - Version Code: #{ENV['VERSION_CODE']}\nSuccessfully uploaded to Google PlayStore. 🚀",
    success: true
  )      
rescue
  UI.error "The Slack WebHook url for the success message inside the release lane is wrong. \nThe app was sucessfully built and uploaded to the Google PlayStore! (Only the Slack success message couldn't be send.)"
end

#======================== END RELEASE LANE ========================#
#==================================================================#
