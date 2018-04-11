# This file represents the Fastfile for the android distribution.
#===========================================================
# Change the syntax highlighting to Ruby
# All lines starting with a # are ignored when running `fastlane`
#===========================================================
# All lanes (public/private) are outsourced to improve the 
# software qualities. (legibility, flexibility, extensibility, testability, ...)
#===========================================================
# Documentation can be found on:
# https://docs.fastlane.tools/
#===========================================================
# Useful terminal commands: (advanced)
# ============================
# sudo fastlane update_fastlane   (force a fastlane update)
# fastlane actions                (shows all available actions)
# ruby -v                         (shows current using ruby version)
# gradle tasks                    (shows all runnable build tasks)
#===========================================================

# This is the minimum required fastlane version number.
# Update this, if you use features of a newer version.
fastlane_version "2.39.2"

# Required ruby version to use fastlane.
# Update this, if you use features of a newer version.
# The ruby version can be found out with the terminal commando: 'ruby -v'
ruby_version "2.0.0"

# Allows to run 'fastlane beta' instead of 'fastlane android beta'
default_platform :android

#----------------------- PATHS ----------------------------------#

# Beta release for testing
ENV['BETA_PATH'] = 'beta.rb'
# Store release for the Google PlayStore
ENV['PLAYSTORE_PATH'] = 'playstore.rb'
# Cleans the git repository
ENV['CLEAN_PATH'] = 'clean.rb'
# Private build lane
ENV['BUILD_PATH'] = 'build.rb'
# Core - contains outsourced methods
ENV['CORE_PATH'] = 'core.rb'

#----------------------- SETTINGS -------------------------------#

# Otherwiese similar github issues would be shown if an error occurs.
ENV["FASTLANE_HIDE_GITHUB_ISSUES"] = "1"

# Otherwise will fastlane itself collect the information, which actions were run.
opt_out_usage             # https://docs.fastlane.tools/actions/#opt_out_usage

# Otherwise will fastlane send a report to itself when a crash occures.
opt_out_crash_reporting   # https://github.com/fastlane/fastlane#crash-reporting 

# Otherwise README.md will be created after each run.
skip_docs                 # https://docs.fastlane.tools/actions/#skip_docs

#---------------------- FIXED VALUES -----------------------------#

# Follow https://api.slack.com/incoming-webhooks to get a Slack Webhook Url
ENV['SLACK_URL'] = 'XXXX'

# Necessary to identify the Fabric.io account.
# Follow https://docs.fabric.io/android/fabric/settings/api-keys.html to get the keys.
# The 'Api Token' and 'Build Secret' is for each app the same (Fabric acc specific).
ENV['FABRIC_API_TOKEN']    = 'XXX'
ENV['FABRIC_BUILD_SECRET'] = 'XXX'

#------------ OWN GLOBAL ENVIRONMENT VARIABLES ------------------#

ENV['EXCUTED_LANE']     = nil
ENV['VERSION_CODE']     = nil
ENV['VERSION_NAME']     = nil
ENV['APP_OUTPUT_PATHS'] = nil

#------------------------------------------------------------------
# Creates the needed path to import outsorced files.
#------------------------------------------------------------------
# IN:     path - the destination which needs to be reached
# RETURN: the full path to that outsourced lane
#------------------------------------------------------------------
def getPath(path)
  return ENV['FASTLANE_HOME'] + '/Android/implementation/' + path 
end

#=================================================================#
#===================== FASTLANE FOR ANDROID ======================#
#=================================================================#

platform :android do

  #====================== BEFORE ALL =============================#

  before_all do
    # https://docs.fastlane.tools/actions/#update_fastlane
    update_fastlane
    # core contains necessary methods which are needed on multiple places 
    import getPath(ENV['CORE_PATH'])
  end

  #======================= PUBLIC LANES ==========================#

  # terminal command to start: 'fastlane beta'
  desc "Deploys a new version and upload to Fabrics test platform 'Beta'."
  lane :beta do 
    import getPath(ENV['BETA_PATH'])
  end
  
  # terminal command to start: 'fastlane release'
  desc "Deploys a new version and upload to Google PlayStore."
  lane :release do 
    import getPath(ENV['PLAYSTORE_PATH'])
  end

  # terminal command to start: 'fastlane clean'
  desc "Cleans the current git repository. (hard reset)"
  lane :clean do 
    import getPath(ENV['CLEAN_PATH'])
  end

  #======================= PRIVATE LANES =========================#

  # private_lane :build
  private_lane :build do
    import getPath(ENV['BUILD_PATH'])
  end

  #======================= IF ERROR OCCURS =======================#

  error do |lane, exception|
    UI.header "Error Lane"
    UI.error "An error occured, see details above and afterwards."

    repoName = getRepoName()  
    begin  
      slack(
        message: "An error occured while running the distribution!\n" + "Repo: " + ((repoName) ? "#{repoName}" : "Couldn't abstract from git"),
        success: false
      )
    rescue
      UI.error "The Slack WebHook url for the error message is wrong."
    end
  end  
end
