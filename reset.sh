git checkout demo2start -- alpine-curl/Dockerfile
git checkout demo2start -- alpha-blog/Dockerfile
git checkout demo2start -- alpha-blog/Dockerfile.rubyfixes
git checkout demo2start -- alpha-blog/Gemfile
git checkout demo2start -- alpha-blog/Gemfile.lock
git add -A
git commit -m "reset $(date +'%y%m%d-%H%M')"
git push origin master