# core.rb / contains all helper methods for the Android distribution
#=================================================================#
# The core method contains all methods who are needed on multiple 
# places, it improves the software qualities.
#=================================================================#

#------------------------------------------------------------------
# Checks if the string contains only integer values.
#------------------------------------------------------------------
# IN: string - the value to test
#------------------------------------------------------------------
def is_Int?(string)
  true if Integer(string) rescue false
end

#------------------------------------------------------------------
# Returs the current gitlab project name from the url - git based.
#------------------------------------------------------------------
# RETURN: the current gitlab project name or nil
#------------------------------------------------------------------
def getRepoName
  begin
    url = sh("git remote show origin -n | grep 'Fetch URL:'")
    return url.split(/\//).last
  rescue
    UI.error "The gitlab project name couldn't be abstract."
    return nil
  end
end

#------------------------------------------------------------------
# Returns the version code which represent the timestand of the 
# last git commit.
#------------------------------------------------------------------
# Timestand schema: YYMMDDHHMM
#------------------------------------------------------------------
# RETURN: the version code for the build process
#------------------------------------------------------------------
def getCheckedVersionCode
  lastCommit = sh("git log -1 --date=short --date=format:%y%m%d%H%M")   
  lastCommitArr = lastCommit.split("\n")
  arrIndex = lastCommitArr.find_index{ |e| e.match( /Datum|Date/ ) }

  versionCode = lastCommitArr[arrIndex].scan(/\d+/).first
  
  if ((not is_Int?(versionCode)) || (versionCode.length != 10)) 
    UI.user_error!("Error by extracting the date from the last git commit.\nThe date is needed to set the new versionCode and must be numeric.\nFollowing result did we got: " +  ((versionCode) ? versionCode : "nil"))
  end
  return versionCode
end