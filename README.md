# Gitlab-String-Searcher
This script will traverse all the projects in a specified group and search for a specified string
# **Requirements**
`GITLAB_TOKEN`="gitlab access token" \
`GITLAB_API_URL`="https://gitlab.com/api/v4" \
`GROUP_ID`="id of group you want to search for string" \
`STRING_TO_SEARCH`=text which is required to be search

This script will keep the record of the files in which it has found the matched text. The name of the file will be in the following format
`liquibase_latest_prj$(date +"%Y-%m-%d_%H-%M-%S").txt`
