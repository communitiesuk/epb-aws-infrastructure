# Codebuild Image Pipeline

Pipeline for building dockers images from a named repo.

## Adding a new image

1. Add the dockerfile and required files to the `communitiesuk/epb-docker-images` repo
2. Add an entry to the `variables.tf` file in this repo, the key must be the name
    of the folder where the dockerfile is located in the 
    `communitiesuk/epb-docker-images` repo. eg:
    ```hcl-terraform
    variable "configurations" {
      description = "The configurations to create docker pipelines for"
      default = {
        "codebuild-cloudfoundry" = {
    
        }
      }
    }
    ```
3. Run `tf apply`
