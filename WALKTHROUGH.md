## Four steps to fixing container image vulnerabilities

1. Make sure your code and dependencies are secure
2. Pick a good base image - slim images are generally recommended for best practices and this has a real implications for security as well
    * Fewer pre-installed operating system packages means fewer vulns to deal with
    * You have more direct control over exactly what goes in to the container
    * Even if you pick the slimmest base image available you still have to keep it updated!
    * Docker regularly updates popular images so node:slim today and node:slim a month are likely to be different
3. Take care of vulns in your own added tools & libraries
    * Good practice: separate out `dev` builds from `prod` builds (and any other stages you might need...`test`, `qa`, `useracceptance`, whatever)...hint: think multi-stage builds to save yourself some headaches!
    * Focus on high risk vulns that could make it production
4. Avoid making problems worse by not using `root` for your apps, limiting resources that your containers can use, etc.
    * This can be applied on the container via the Dockerfile, Compose file, or Kubernetes YAML...not a horrible idea to apply it everywhere you can

The demos below focus on the first 3 items in this list, but if you look at the Dockerfiles there are settings that apply to step 4 as well.

## Setup for the exercises from the demos

* The files you'll need are accessible from `https://github.com/jimcodified/dockercon2020`:

```bash
$> git clone https://github.com/jimcodified/dockercon2020
```

If you want to use the Snyk scanner you'll need to download it. You can sign-up and use Snyk for free at https://snyk.io/sign-up. Then you can download and install the CLI scanner or use the Snyk UI.
* A quick start for installing using the CLI is available [here](https://support.snyk.io/hc/en-us/articles/360003087017-How-to-find-vulnerabilities-using-your-CLI).
* Full docs for Snyk are at https://snyk.io/docs

---

## Part 1: Fixing a simple container image

* In the first example we'll use a very simple utility container. That means there's no custom code of our own inside it, just a simple Linux utility that we install on top of a base image.

> The files for this exercise are in the `alpine-curl` folder.

* So from the _Four steps..._ above we don't have to worry about Step 1.

* So let's address the base image and what's installed

---

## Part 2: Fixing User Instructions

* /usr/local/lib/ruby/site_ruby/2.7.0/rubygems/core_ext/kernel_gem.rb:67:in `synchronize': deadlock; recursive locking (ThreadError)
  * Seems related to wrong version of ruby (2.5 in original -- need to go to 2.7)
  * Change Gemfile to use Ruby 2.7
  * Still get same error - remove Gemfile.lock
