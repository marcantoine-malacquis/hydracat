# Git Memo

## Check which branch you're on
```
git branch
```

## Add all changes to staging area (prepare for commit)
```
git add .
```

## Commit changes to LOCAL repository with a message
```
git commit -m "Your commit message here"
```
*Important: This saves to your LOCAL repository, not GitHub yet*

## Push commits to remote repository (GitHub)
```
git push
```
*This uploads your local commits to GitHub*


## Create a new branch locally and switch to it
```
git checkout -b new-branch-name
```

## Push new branch to remote repository (first time)
```
git push --set-upstream origin new-branch-name
```
*After this, you can just use `git push` for this branch*

## Switch between existing branches
```
git checkout branch-name
```

## See what files have changed
```
git status
```
*Very useful - shows what's been modified, added, or deleted*