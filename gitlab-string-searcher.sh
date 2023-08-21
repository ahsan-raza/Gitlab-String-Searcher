#!/bin/bash

# Set your GitLab API token and the base GitLab API URL
GITLAB_TOKEN=""
GITLAB_API_URL="https://gitlab.com/api/v4"
GROUP_ID=""

STRING_TO_SEARCH='ARG BUILD_IMAGE_TAG="latest"'
liquibase_latest_prj="liquibase_latest_prj$(date +"%Y-%m-%d_%H-%M-%S").txt"
echo "" > "$liquibase_latest_prj"

# number_of_pages=$(curl -s --head "$GITLAB_API_URL/groups/$GROUP_ID/projects?include_subgroups&private_token=$GITLAB_TOKEN" | grep -i x-total-pages | awk '{print $2}' | tr -d '\r\n')

# Function to retrieve projects list within a specific group
get_group_projects() {
  curl  -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/groups/$GROUP_ID/projects?include_subgroups=true&per_page=100&page=$1"
}

# Loop through projects within the group
page=1
while true; do
  group_projects=$(get_group_projects "$page")
  
  # Exit the loop if no more projects in the group
  if [ "$group_projects"  == "[]" ]; then
    break
  fi
  echo -e "page number: $page\n"
  project_ids=($(echo "$group_projects" | jq -r '.[].id'))
  for project_id in "${project_ids[@]}"; do
    project_name=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$project_id" | jq -r .name)
    default_branch=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$project_id" | jq -r '.default_branch')
    echo "Checking project ID: $project_id in Project : $project_name"
    echo "Default Branch of Project: $project_name is : $default_branch"
    # Retrieve Dockerfiles for each project within the group
    dockerfiles=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$project_id/repository/tree?ref=$default_branch" | jq -r '.[] | select(.type == "tree" or (.name | endswith("/")) | not) | select(.name | test("(?i)Dockerfile_Liquibase")) | .name')
    
    for dockerfile in $dockerfiles; do
      echo "Reading Dockerfile: $dockerfile"
      
      # Capture lines containing "liquibase"
      liquibase_lines=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL/projects/$project_id/repository/files/$dockerfile/raw?ref=$default_branch" | grep -i "$STRING_TO_SEARCH")
      
      if [ -n "$liquibase_lines" ]; then
        echo "Liquibase found in project ID: $project_id, Project Name: $project_name Dockerfile: $dockerfile"
        echo -e "Liquibase Latest found in project ID: $project_id, Project Name: $project_name Dockerfile: $dockerfile" >> $liquibase_latest_prj
        echo "$liquibase_lines"
      fi
    done
  done
  
  ((page++))
done
