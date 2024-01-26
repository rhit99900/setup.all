# Install HomeBrew 
if type brew:
  
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"



# Update ShortCuts
# cat << EOF >> ~./.zprofile


function _exists {

  type "$1" $> /dev/null
}