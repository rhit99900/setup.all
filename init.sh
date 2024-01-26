# Install HomeBrew 

installer_dir="__installers"
mkdir $installer_dir

if command -v "brew" &> /dev/null; then
  echo "Brew is already installed"
else
  echo "Homebrew not found. Installing now"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Installing NodeJS
if command -v node &> /dev/null; then
  echo "NodeJS is already installed. Skipping"
else
  # Installing NVM (Node Version Manager)
  if command -v nvm &> /dev/null; then 
    echo "nvm is already installed"
  else
    cd $installer_dir
    mkdir nvm 
    cd nvm
    echo "nvm not found. Installing now"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    cd ../..
  fi
  
  nvm install 16
  nvm use 16
fi