# Contributing Guide

In this guide you can find detailed instructions to setup this project easily.

## Developing locally

You should be able to do the typical stuff:

### 1. Cloning repository:
Fork the repository and run this(Only for SSH):

```
git clone git@github.com:${your_github_username}/foobara.git
```

Create a new branch for you to push into

```
git checkout -b <branch-name>
```

Now navigate to project directory

```
cd foobara
```

### 2. Installing mise (LINUX/WSL)
Mise is a package manager and helps with managing different versions of ruby. It allows you to switch different versions of ruby.

The installation docs might be updated by mise so here's the reference to that: [Installation Docs](https://mise.jdx.dev/installing-mise.html)

***If you already installed by following mise's docs then, you can skip this section***

Else to setup mise follow the script given below:

```
sudo apt update -y && sudo apt install -y gpg wget \
build-essential \
  libssl-dev zlib1g-dev libreadline-dev libyaml-dev libxml2-dev \
  libxslt1-dev libffi-dev libgdbm-dev autoconf bison
wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
sudo apt update
sudo apt install -y mise
```

Verify if it's installed or not by running:

```
mise -v
```

It should print out an ascii-art saying "mise-en-place"

### 3. Install required ruby version
In this project, currently we require ruby version >=3.4 so we can install it manually using the command below

```
mise use -g ruby@3.4
```

In case, you want to automatically activate the ruby version whenever you navigate to the directory containing .ruby-version file

This helps a lot when you have lot of ruby projects with different versions and don't want to switch ruby versions each time manually

```
mise settings add idiomatic_version_file_enable_tools ruby
```

### 4. Activating mise
We can activate mise so that it will update the environment variables such that we will use the correct version of ruby.

```
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
```

Restart the terminal

Now environment variables are updated and you can verify it by running:

```
ruby -v
```

It will print out the ruby version, which is mentioned in .ruby-version file

You can list out your mise tools and its versions by running:

```
mise list
```

### 5. Running tests
Before running test-suite, we need to install all the dependencies

Run this to install all the dependencies:

```
bundle
```

Run the tests now:

```
rake
```

And if the tests/linter pass then you could dive into modifying the code.