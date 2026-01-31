for repo in ~/Code/*/; do
    if [ -d "$repo" ] && [ -d "$repo/.git" ]; then
        (
            cd $repo || exit
            git checkout main
            git branch --set-upstream-to origin/main
        )
    fi
done;
