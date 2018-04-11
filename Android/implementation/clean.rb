# clean.rb / public lane :clean
#===================================================================
# Cleans the current git repository, if there is something to clean.
#===================================================================

#==================================================================#
#==================== START CLEAN LANE ============================#
#==================================================================#

#=========================== START ================================#

begin
  repo_status = sh("git status --porcelain")
  if (repo_status.empty?)
    UI.success "There was nothing to do, the git repository is already clean. 🐣"
  else
    changedFiles = sh("git diff --name-only")
    newFiles = sh("cd .. ; git ls-files --others --exclude-standard")

    UI.header "Following changes would be discard:"
    UI.message "\n\n#{changedFiles}#{newFiles}"

    if UI.confirm("The listed file changes would be discard. Continue?")
      reset_git_repo(
        force: true,
        disregard_gitignore: false
      )
      UI.success "The repository was cleaned. ✨"
    else
      UI.error "Abort, nothing was made!"
    end  
  end
rescue
  UI.user_error!("An Error occurred while tried to process a git command.")
end

#========================= END CLEAN LANE =========================#
#==================================================================#
