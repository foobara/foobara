In this guide you can find detailed instructions to setup this project easily.

<!-- TOC -->
* [Setting Up Your Dev Environment](#setting-up-your-dev-environment)
  * [Forking/Cloning the Repository](#forkingcloning-the-repository)
  * [Bundle!](#bundle)
  * [Run the Test Suite to Make Sure All's Well](#run-the-test-suite-to-make-sure-alls-well)
* [Understanding this Project's Directory Structure](#understanding-this-projects-directory-structure)
  * [Per-project Structure](#per-project-structure)
* [Rules to Follow When Making git commits](#rules-to-follow-when-making-git-commits)
* [How do I...](#how-do-i)
  * [Test integration of foobara/foobara monorepo with some other foobara/whatever project](#test-integration-of-foobarafoobara-monorepo-with-some-other-foobarawhatever-project)
* [Installing Ruby](#installing-ruby)
  * [Installing mise (LINUX/WSL)](#installing-mise-linuxwsl)
    * [Install required ruby version](#install-required-ruby-version)
    * [Activating mise](#activating-mise)
    * [Running tests](#running-tests)
<!-- TOC -->

# Setting Up Your Dev Environment

We assume you have a working Ruby installation but if not you might be able to find a way to get
setup in the [Installing Ruby](#installing-ruby) section.

## Forking/Cloning the Repository

Fork the repository on GitHub and run this (if using SSH):

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

## Bundle!

`bundle`

## Run the Test Suite to Make Sure All's Well

`bundle exec rake`

You might not need to run it with `bundle exec ` preceding `rake`, depending on your setup.

If it is all green, then you are ready to start hackin' on Foobara!

# Understanding this Project's Directory Structure

This repository is currently a monorepo made of 6 projects. You can see these projects in `/projects/`
as they each have their own directory. Two of these projects are themselves monorepos! Those are 
`typesystem` and `entities`. The goal is to eventually extract `entities` out of this monorepo entirely
to allow the rest to be released as version 1.0 sooner.

Projects have been extracted from this monorepo in the past and will continue to be when it makes sense or
is part of the roadmap. The full ecosystem of foobara projects can be seen at https://github.com/foobara/ 
(there's a lot of them!)

## Per-project Structure

Projects have both a `lib/` and `src/` directory which is not a common setup. `lib/` contains things
that are expected to be fine to `require` from outside this project. `src/` contains everything else
that should not be in the load path in order to keep the load path entries smaller and less confusing.

Within src/ things are often automatically loaded in a desirable order to not necessitate `require_relative`
but you might occasionally need to call `require_relative` within `<some_project>/src/` to make sure that
the two project files are loaded in the right order.

Each project can have its own `spec/` directory with its own test suite. These can be ran in parallel or
in serial using tasks in the `Rakefile`.  There is also actually a top-level `spec/` directory which
someday should go away as everything is moved to appropriate projects.

100% line coverage is required to get a green build. This coverage is assembled from all of the test suites
so you don't need an individual test suite to have 100% line coverage but running all of them must cover
everything from all projects.

# Rules to Follow When Making git commits

1. Do not place a file rename and an edit to that file in the same commit. Leave these as separate commits.
   This helps git tooling follow history and helps a lot with scripts like extract-repo.

# How do I...

## Test integration of foobara/foobara monorepo with some other foobara/whatever project

You can change the entries in Gemfile of whichever projects to use `path:` to point to your local copy
of whichever foobara project. This can be a convenient way to test integration behavior directly
without having to publish your changes first.

# Installing Ruby

One option (of many) is to use mise. Here are some instructions, if helpful!

## Installing mise (LINUX/WSL)

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

### Install required ruby version

In this project, currently we require ruby version >=3.4 so we can install it manually using the command below

```
mise use -g ruby@3.4
```

In case, you want to automatically activate the ruby version whenever you navigate to the directory containing .ruby-version file

This helps a lot when you have lot of ruby projects with different versions and don't want to switch ruby versions each time manually

```
mise settings add idiomatic_version_file_enable_tools ruby
```

### Activating mise

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

### Running tests

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
