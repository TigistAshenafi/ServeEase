1.Clone the project first time only

git clone <repo-link>
cd <repo-name>

2.Create a new branch for your work

git checkout main
git pull origin main
git checkout -b ur_branch_name

3.Do your work and save it

git add .
git commit -m "ur comment"

4.Push your branch to GitHub

git push -u origin ur_branch_name

5.Open a Pull Request (PR)

//Go to GitHub → your repo.
//You’ll see a button “Compare & pull request” — click it.
//Add a short description of what you did.
//Request a review from your teammate.

6.Review, fix (if needed), then merge (If your teammate asks for changes)

// make fixes
git add .
git commit -m "Fixed login button alignment"
git push

//When everything looks good → click Merge on GitHub.

7.Update your main branch

git checkout main
git pull origin main
git merge ur_branch_name

// Delete your old branch
git branch -d ur_branch_name
git push origin --delete ur_branch_name



I don't think this is enough; let's document all the steps in progress. 
Also, let's use more professional branch names and commit messages.

eg.,Type	Branch Name Example
Feature	       feature/authentication-backend
Bugfix	       bugfix/login-error



