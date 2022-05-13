!#/bin/sh
git stash
git remote add template https://github.com/mccbryan3/wiz_se_demo_template
git fetch --all
git rebase template/main
git rebase origin container-pass
git rebase origin container-fail
git rebase origin iac-pass
git rebase origin iac-fail
git checkout container-pass  
git push --force
git checkout container-fail 
git push --force
git checkout iac-pass  
git push --force
git checkout iac-fail  
git push --force