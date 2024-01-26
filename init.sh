# Install HomeBrew 
if command -v "brew" &> /dev/null; then
  echo "Brew is already installed"
else
  echo "Homebrew not found. Installing Brew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi