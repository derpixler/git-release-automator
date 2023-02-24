#!/bin/bash

################################################################################
# Script Name: git-release-automator.sh
# Author: René Reimann (info@rene-reimann.de)
# Version: v1.0.0
#
# Description:
# Automated script for Git release tagging and creation of release branches for
# major and minor versions. Fetches latest Git tag and prompts user to update
# major, minor, or patch version. Creates new Git tag and release branch, e.g.
# "release/v1.1.0", and pushes it to the remote repository if no release branch
# is available.
#
################################################################################

# Function that creates a new git tag and pushes it to the remote repository
function create_and_push_git_tag()
{
    new_tag=$1

    # Create git tag
    echo "git tag $new_tag"
    git tag $new_tag

    # Push tag to remote repository
    git push origin $new_tag

    # Display success message
    echo "Git tag $new_tag created and pushed successfully."
}

function get_current_release_branch()
{
  local version="$1"
  local release_branch="release/$version"

  echo $(git branch --list "$release_branch" | tail -1)
}

# Check if the current branch is a release branch
function create_release_branch()
{
  local release_branch_name="release/$1"

  # Try to switch to an existing release branch
  release_branch=$(git branch --list $release_branch_name | grep $release_branch_name)

  if [ -z "$release_branch" ]; then
      # Create a new release branch
      git checkout -b $release_branch_name > /dev/null
      git push origin $release_branch_name > /dev/null
      echo "Created release branch $release_branch_name"
  else
      git checkout $release_branch > /dev/null
      echo "Switched to existing release branch $release_branch_name"
  fi
}

if [ -d ".git" ]; then
	# Get the latest git tag
	git fetch --all --tags --prune > /dev/null

	latest_origin_tag=$(git ls-remote --tags origin | awk '{print $2}' | grep -v '{}' | awk -F"/" '{print $3}' | grep -v '@' | sort -V | tail -1)
  tag_prefix=$(echo $latest_origin_tag | grep -E '^v')
  latest_tag=$(echo $latest_origin_tag | sed 's/^v//')

  # Check if there are existing tags
  if [ -n "$latest_tag" ]; then
    choice=$1

    if [ ! "$choice" ]; then
      # Ask the user which version number (Major, Minor, or Patch) to increase
      echo "Latest tag: ${tag_prefix:+v}$latest_tag"
      echo "Which version number do you want to increase? (M.m.p)"
      read -n 1 -r -p "Your choice: " choice
      echo
    fi

    if [ "$choice" == "M" ]; then
        # Increase Major version
        new_tag_number=$(echo $latest_tag | awk -F. '{ printf("%d.%d.%d", $1 + 1, 0, 0) }')
    elif [ "$choice" == "m" ]; then
        # Increase Minor version
        new_tag_number=$(echo $latest_tag | awk -F. '{ printf("%d.%d.0", $1, $2 + 1) }')
    elif [ "$choice" == "p" ]; then
        # Increase Patch version
        new_tag_number=$(echo $latest_tag | awk -F. '{ printf("%d.%d.%d", $1, $2, $3 + 1) }')
    else
        echo "Invalid input."
        exit 1
    fi

    # Create and push the new git tag
    new_tag="${tag_prefix:+v}$new_tag_number"

    if [ "$choice" == "p" ]; then
      current_release_branch=$(echo $new_tag | sed 's/.$/0/')
      echo "Create tag $new_tag at the current release branch"
      create_release_branch $current_release_branch
    else
      create_release_branch $new_tag
    fi

    create_and_push_git_tag $new_tag

  else
    # Ask the user if the new tag should start with "v" or not
    echo "There are no existing tags. Do you want to create a tag starting with 'v'? (y/n)"
    read -n 1 -r -p "Your choice: " choice
    echo

    if [ "$choice" == "y" ]; then
        # Create and push the new git tag with "v"
        new_tag="v1.0.0"
        create_and_push_git_tag $new_tag
    elif [ "$choice" == "n" ]; then
        # Create and push the new git tag without "v"
        new_tag="1.0.0"
        create_and_push_git_tag $new_tag
    else
        echo "Invalid input."
        exit 1
    fi
  fi
else
  echo "This directory does not contain a Git repository."
  exit 1
fi