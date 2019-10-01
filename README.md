# git-studio

A shell environment you can share via git

## Getting started

1. Initialize a new repo (preferrably private, encrypted, and secure -- keybase is a good option)
2. Create initial `.studiorc` file in the root of the repository:

    ```bash
    #!/bin/bash


    # load git-studio
    hab pkg install jarvus/git-studio
    source "$(hab pkg path jarvus/git-studio)/studio.sh"


    # disable Habitat studio supervisor
    export HAB_STUDIO_SUP=false
    ```
