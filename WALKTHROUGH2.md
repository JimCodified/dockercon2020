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

But let's check our image for vulnerabilities:

```bash
snyk test --docker jimcodified/dockercon2020:alpha-blog.ossfixes --file=Dockerfile
```




* /usr/local/lib/ruby/site_ruby/2.7.0/rubygems/core_ext/kernel_gem.rb:67:in `synchronize': deadlock; recursive locking (ThreadError)
  * Seems related to wrong version of ruby (2.5 in original -- need to go to 2.7)
  * Change Gemfile to use Ruby 2.7
  * Still get same error - remove Gemfile.lock