# DockerCon 2020:
## Part 2 of _You've got container vulnerabilities. Now what?_ exercises

> If you haven't done it already, [Part 1](WALKTHROUGH.md) of the walkthrough introduces you to Snyk and gives a simple container image example to clean up.

---

### Setup

> **IMPORTANT:** If you have Ruby installed on your system or tools that manage Ruby version like rvm, you may get some warnings when you go in to the alpha-blog directory. Ignore them - everything that needs to be done will be handled in the steps below and inside the container so don't try to fix any warnings at this point.

If you did Part 1 you should have everything you need and the files for this section are in the `alpha-blog` directory.

If you did not do Part 1 here are the prerequisites before you get started:

* The files you'll need are accessible from `https://github.com/jimcodified/dockercon2020`:

```bash
git clone https://github.com/jimcodified/dockercon2020
```

If you want to use the Snyk scanner you'll need to download it. You can sign-up and use Snyk for free at https://snyk.io/sign-up. Then you can download and install the CLI scanner or use the Snyk UI.
* A quick start for installing using the CLI is available [here](https://support.snyk.io/hc/en-us/articles/360003087017-How-to-find-vulnerabilities-using-your-CLI).
* Full docs for Snyk are at https://snyk.io/docs

> A huge shout-out to the Docker Hub user [Aditya Avanth](https://hub.docker.com/u/avantaditya) who took the Alpha Blog app from the course, containerized it, and provide the initial Dockerfile and code you see here. This saved me hours of prep time for this demo! In their original, Aditya has Jenkins files, Kubernetes deployment files...this really has everyhing. Check it out on their [Github repo](https://github.com/kavaka123/alpha-blog.git)!

---

## Part 2: Fixing a more complex image

In this example, we're going to investigate a more complex example that requires us to make some code changes. The demo app uses Ruby on Rails but if you're not a Rails developer you should still be able to complete the steps below. The process will apply to just about any language you prefer.

In this example we have a real, working application. We'll use our steps 1-3 of the "Fixing Container Vulns" process to take care of vulnerabilities in our app:
* Fixing vulnerabilities in our code
* Addressing issues in our base image
* Addressing issues we introduce into the image

---

## A bit of background

This is a Ruby on Rails app (don't fret if you're not a Ruby dev). You can check out the code and the Dockerfile. The app itself is called *Alpha Blog* and it's an app that you can build in the Udemy course [_The Complete Ruby on Rails Developer Course_](https://www.udemy.com/course/the-complete-ruby-on-rails-developer-course/). Lovely course - I recommend it if you want to learn Ruby on Rails, but don't worry if you don't know either...the walkthrough will guide you through everything.

What we have is an app using Ruby 2.5.1, Rails 5.2.4 and a bunch of other Gems. All of these have their own dependencies, of course, so when you setup the app you're getting a ton of open source code.

As it relates to the container image, the original image (`jimcodified/dockercon2020:alpha-blog.orig`) is built to match those specs. It uses `ruby:2.5.1` as the base image and then a bunch of other tools and dependencies are installed, the app gets setup, and then launches.

Feel free to run the app if you want - you should get a functioning blog app running on port 3000:

```bash
docker run -p 3000:3000 --rm jimcodified/dockercon2020:alpha-blog.orig
```

You could also build your own image from the included Dockerfile as well, by the way, which we'll do in a bit.

---

## Dealing with the vulnerabilities in code

Our 4-step process started with dealing with the code vulnerabilities first. Snyk can help us see what we need to do here:

```bash
snyk test --all-projects
```

And you should see a whole list of vulnerabilities:
![dependency vulnerabilities](/images/demo2-code-vulns.png)

Now, we could go through our Gemfile and update all our versions per the results, but Snyk makes this even easier for us. If you push the code up to your own git-style repo (Github, Gitlab, Bitbucket, etc) you can scan directly from there and Snyk gives you the option to open Fix PRs to automatically address all these issues. A quick overview of this works:

![Snyk Open Source fixes](/images/demo2-snyk-opensource-fixes.png)

- Top image: we import the project from Github (or your SCM of choice). Snyk detects several applicable files including Ruby's Gemfile, Node's package.json, and some Kubernetes config files. We only care about the Gemfile today.
- If you click on the `Gemfile.lock` results you can see the details of the scan. Same results as we saw in the CLI above, but now because we're in SCM we can do Fix PRs to automatically address most of the issues. Go ahead and click that _Open a Fix PR_ button.
- Now you get a review of which vulnerabilities will be fixed. There's another _Open a Fix PR_ button to confirm you want to proceed.
- Then you're taken to your SCM to see the PR and review code changes.
- I did a quick `git pull` to grab the new `snyk-fix` branch before merging. Did a 2nd test from the CLI to confirm all the issues in the Fix PR were addressed.
- Merge away!

--- 

## Dealing with the vulnerabilities in the base image

Next up, our container. As noted earlier, this is a Ruby 2.5.1 project, so it's no surprise that we're using the `ruby:2.5.1` base image for our app. This is shown in the 1st line of the Dockerfile:

```dockerfile
FROM ruby:2.5.1
```

Since we just fixed up a bunch of vulnerabilities in our code let's build, make sure the app still works, and then we'll look at the vulnerabilities in the image:

```bash
docker build -t jimcodified/dockercon2020:alpha-blog.ossfixes .

# when the above is completed:
docker run -p 3000:3000 --rm jimcodified/dockercon2020:alpha-blog.ossfixes
```

You should be able to open up a browser to http://localhost:3000 and see the app running. It's functional - if you want to login just create a new login and you can even add articles, categories, etc.

But let's check our image for vulnerabilities (don't forget to substitute your own image tag in place of mine if you customized in the build above):

```bash
snyk test --docker jimcodified/dockercon2020:alpha-blog.ossfixes --file=Dockerfile
```

You should get a pretty long list of issues and final output that looks like this:
![container vulns](/images/demo2-original-image.png)

* Item (1) here is the total number of vulnerabilities: 826! That's a big number. We can see just below this that 42 of these vulns are High severity and those are where we'll focus our attention.
* Item (2) in the graphic is Snyk's _Base Image Recommendation_ feature. We saw something like this Exercise 1, but that was much simpler. This time we have multiple options:
  * The "Minor" upgrade to Ruby 2.5 gets our base image down to 279 issues. Not bad, but there's still 1 High sev there.
  * The "Alternative" options get us to `slim` images and also to a new version of Ruby. They're listed as _Alternative_ because we changing what is packaged in the OS layers from the base image and because we have a change in the Ruby version, which can affect how our app works.
* Item (3) in this image is a specific vulnerability and, just like Exercise 1, we can see the exact line in our Dockerfile that introduced this vuln. 
  * Also notice that the vuln itself is in something called `libssh/libssh2-1`. Clearly that's something to do with SSH but we installed `git` and `vim` from the Dockerfile
  * The `From:` line shows us our dependency mapping. The `libssh` is part of `curl` which was installed with `git`. So that's our culprit. We'll come back to this after we clean up the base image vulns.

Focusing on items 1 & 2 in the image, which relates to our base image. For the purposes of this exercise, we're going to go with `ruby:2.7.0-slim-buster` as our new base image. It gets us to a slim image, gets rid of all the High sev vulns, and is a slightly newer version of Ruby and if we have to make any changes to our app for that change I want to try and do it once and have it last for a while.

So let's modify the Dockerfile. We'll start by editing only the first line - the `FROM` line - to use our new slim base image. You can use whatever text or code editor you like but line 1 in your Dockerfile should look like this:

```dockerfile
FROM ruby:2.7.0-slim-buster
```

We're going to hope that it just magically works with the Ruby 2.5 code we have in our app...spoiler alert: it won't.

You'll get some errors when you build that tell you the `RUN bundle update...` command failed. If you want a challenge or if you know Ruby and Rails you can probably sort through these issues on your own but here's what happened:

1. When we change the base image to one with Ruby 2.7.0 we also got a new version of bundler and our Dockerfile is explicitly calling for `BUNDLER 2.0.2` - you'll see this in line 8 where we installed bundler and the `ENV` in line 15. The new image has bundler 2.1.2.
2. The RubyGems in the new image is version 3.1.2 and our original Dockerfile had 3.0.4.
3. When we went to the `slim` image it removed a bunch of libraries and some of those libraries are needed for our Ruby Gems.
4. And, of course, we need to update the Gemfile with all our new versions as well. Again, that's done for you in a file called `rubyfixes.Gemfile`. You can simply copy this over top of the existing Gemfile. 

So we need to change our Dockerfile to address these things and we need to update our Gemfile for the new versions of Ruby. You can try this on your own, if you want...or you can simply use the `Dockerfile.rubyfixes` file which already has the fixes for all of the above and the `rubyfixes.Gemfile` will fix up our Gems. 😎 You can inspect it them if you like or simply do the following:

```bash
cp rubyfixes.Gemfile Gemfile

docker build -t jimcodified/dockercon2020:alpha-blog.270slim-fixed . -f Dockerfile.rubyfixes
```

Et voila! Our image should build!

You can run it the same way we did earlier to verify the app still works: `docker run -p 3000:3000 --rm jimcodified/dockercon2020:alpha-blog.270slim-fixed` and you should see our beautiful blog app on http://localhost:3000.

> NOTE: If you actually went through the steps of creating a user earlier and then try to connect to the app you might get errors. The app sets a session cookie and since you've built a new version the cookie's no longer valid. You'll have to clear that cookie from your browser (or just open a new private window and connect).

Let's check out the situation with our vulnerabilities now. We _should_ find that all the High sev vulns are gone from our base image. We're going to run a `monitor` command this time, which will send the container image dependency info to your Snyk app console, allowing you to track vulnerabilities in the future...but it also makes it a little easier to read.

```bash
snyk monitor --docker jimcodified/dockercon2020:alpha-blog.270slim-fixed --file=Dockerfile.rubyfixes
```

Now we can open a browser to https://app.snyk.io/ and investigate our findings:
![updated scan results](/images/demo2-update-base-image-scan.png)

Here's what we can see now:

* Near the top are three items marked (1) which show the info about our new image:
  * We have 144 vulns now, down from over 800. Cool!
  * We have a new 2.7.0 slim base image
  * And we still have an alternative base image if we wanted to knock out another 4 Low risk vulns. We won't do that here, in part because I think it's better practice to pin to a more definitive version...especially since we just updated a bunch of Ruby stuff specifically for 2.7.0! That `2-slim` image will update and in the future could be Ruby 2.8.0 or something else and I'd rather be in control of my versions.
* Further down on the left (2) we see an option to filter to see just Base Image vulns or just User introduced vulns.
* And then in the middle we see the details for a particular vuln. Again, we get the Dockerfile instruction that caused this vuln to appear but we also get the dependency information. We installed a bunch of stuff in that single line of the Dockerfile, and all that "stuff" has dependencies that got installed. So just getting vuln info about `gcc-8/libgcc1` doesn't really tell us directly how to fix our container issues. The dependency info and Dockerfile instruction does.
  * In this case, there are 31 different dependencies on this library but the first one - `build-essential` - is something we installed in our new Dockerfile.
  * It's a medium severity vuln so I'm going to ignore it. If you wanted to, you could check for a newer version of build-essential, you could look for a newer version of gcc, or you could figure out what's being built and then in a multi-stage build (probably one of the Gems) and copy the Gems over in a later stage so you don't have all these development libraries.

--- 

## Dealing with vulns in the user layers

Last, but not least, we want to look at those vulns in the user layers and decide what, if anything, we want to fix. 

* At this point, we already have all the High sev vulns removed.
* We did add some development libraries back into our slim image so our Gems would build and as we noted above those did introduce some vulns.
* But we've been installing `vim` and `git` in our image, too. Why? Because the original version of the image pull its code in from a git repo and maybe the original coder wanted to have a text editor in the image, for some reason?

In the Snyk UI console we can filter out base image vulns and just look at what we've introduced. Then we can also search for particular issues from those packages. I already noted that for the development libraries we need those to compile our Gems and would could probably address the vulns through a multi-stage build where we copy Gems over, etc. Let's focus on vim and git.

Do a search for `vim` and `git` in the Snyk UI:
![search for vim](/images/demo2-vim-search.png)

Turns out there's only a handful of Low risk vulns for these. But we don't need them in our image anymore so let's zap 'em and rebuild.

Edit the `Dockerfile.rubyfixes` and remove `vim` and `git` from the `RUN apt-get` line then let's build and test one last time:

```bash
docker build -t jimcodifed/dockercon2020:alpha-blog.lastone . -f Dockerfile.rubyfixes

# when the build is finished:
snyk test --docker jimcodifed/dockercon2020:alpha-blog.lastone --file=Dockerfile.rubyfixes
```

Now we're down to 129 vulns, with no High risk.

Setting up the multi-stage build and copying over Gems is deeper than we'll go here, but again, there's a decent chance we could use those methods to make our container even smaller and get rid of many, if not all, the vulns from those dev libraries we're installing. But that's an exercise for a different day. There's a [great article on Medium](https://medium.com/@lemuelbarango/ruby-on-rails-smaller-docker-images-bff240931332) by Lemuel Barango about this, specifically for Ruby, if you're curious.
