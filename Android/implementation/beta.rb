# beta.rb / public lane :beta
#==================================================================
# The public lane ':beta' realized the android app distribution
# and upload to Fabrics test platform 'Beta'.
#==================================================================

#=================================================================#
#===================== HELPER METHODS ============================#
#=================================================================#

#------------------------------------------------------------------
# Check if all necessary environment variables were filled out.
#------------------------------------------------------------------
# GLOBAL GET ENV['BETA_PRODUCT_FLAVORS']
#------------------------------------------------------------------
def checkIfEnvFilled
  env = ENV['BETA_PRODUCT_FLAVORS']
  UI.user_error!("'ENV['BETA_PRODUCT_FLAVORS']' isn't filled out.") if (env.nil? || env.empty?)

  ENV['BETA_EMAILS'] = nil if (ENV['BETA_EMAILS'].empty?)
  ENV['BETA_GROUPS'] = nil if (ENV['BETA_GROUPS'].empty?)
end

#------------------------------------------------------------------
# Test if the branch name syntax is valid.
# The beta lane can only be excecuted on a release or hotfix branch.
#------------------------------------------------------------------
# Syntax regulation: 
#   lane/number.number.number
#   => lane = 'release' or 'hotfix'
#   => number = 0..999
#------------------------------------------------------------------
# IN:     gitBranch - the git branch where fastlane was started on
# RETURN: an exception will be triggert if git is on a invalid branch
#------------------------------------------------------------------
def checkIfValidGitBranch(gitBranch)
  if (gitBranch =~ /^(release|hotfix)\/\d{1,3}\.\d{1,3}\.\d{1,3}$/)
    UI.message "Valid branch name + syntax!"
  else
    UI.user_error!("The '#{ENV['EXCUTED_LANE']}' lane can only be launched on a `release` or `hotfix` branch.\nCurrent git branch is `" + gitBranch + "`! (Branch name convention: lane/number.number.number)")
  end
end

#------------------------------------------------------------------
# Returns the version name from the given git branch value
# which is needed for the build process afterwards.
#------------------------------------------------------------------
# IN:     gitBranch - the git branch where fastlane was started on
# RETURN: the version name for the build process
#------------------------------------------------------------------
def getCheckedVersionName(gitBranch)
  versionName = gitBranch.split("/").last
  UI.user_error!("The version name couldn't be abstract from the current git branch.") if versionName.empty?
  return versionName
end

#=================================================================#
#==================== START BETA LANE ============================#
#=================================================================#

#====================== BEFORE START =============================#

ENV['EXCUTED_LANE'] = 'beta'
ENV['FLAVORS'] = ENV['BETA_PRODUCT_FLAVORS']

checkIfEnvFilled()

gitBranch = git_branch

# Beta upload can only be launched inside a release or hotfix branch
checkIfValidGitBranch(gitBranch)

#=========================== START ===============================#

#-------------- GET VERSION_CODE AND VERSION_NAME ----------------#

ENV['VERSION_NAME'] = getCheckedVersionName(gitBranch)
ENV['VERSION_CODE'] = getCheckedVersionCode()

UI.message "VersionName: #{ENV['VERSION_NAME']}"
UI.message "VersionCode: #{ENV['VERSION_CODE']}"

#----------------------- GET CHANGELOG ---------------------------#

changelog = prompt(text: "Enter the release overview URL: (Version: #{ENV['VERSION_NAME']} '#{ENV['VERSION_CODE']}')")

#--------------------------- BUILD -------------------------------#

# start private lane :build
# All global environment variable for the build lane are filled out.
build()

#------------------------- CRASHLYTICS ---------------------------#

ENV['APP_OUTPUT_PATHS'].split(',').each do |apkPath|
  UI.header "Next upload to Fabric: #{apkPath}"
  crashlytics(
    apk_path: apkPath,
    api_token: ENV['FABRIC_API_TOKEN'],
    build_secret: ENV['FABRIC_BUILD_SECRET'],
    emails: ENV['BETA_EMAILS'],
    groups: ENV['BETA_GROUPS'],
    notes: changelog
  )
end

#---------------------------- SLACK -------------------------------#

repoName = getRepoName() 

begin      
  slack(
    message: "Repo: " + ((repoName) ? "#{repoName}" : "Couldn't abstract from git\n") + "Flavors: #{ENV['FLAVORS']}\nVersion Name: #{ENV['VERSION_NAME']} - Version Code: #{ENV['VERSION_CODE']}\nSuccessfully uploaded to Fabrics test platform Beta, all notifications were sent. 🚀",
    success: true
  )
rescue
  UI.error "The Slack WebHook url for the success message inside the beta lane is wrong. \nThe app was sucessfully built and uploaded to Beta! The testers are also informed but the Slack message couldn't be sent."
end

#========================== END BETA LANE =========================#
#==================================================================#
