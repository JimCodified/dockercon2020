# DockerCon 2020:
## _You've got container vulnerabilities. Now what?_
## Walkthrough Part 2

> If you haven't done it already, [Part 1](WALKTHROUGH.md) of the walkthrough introduces you to Snyk and gives a simple container image example to clean up.


## Part 2: Fixing a more complex image

In this example, we're going to investigate a more complex example that requires us to make some code changes. The demo app uses Ruby on Rails but if you're not a Rails developer you should still be able to complete the steps below. The process will apply to just about any language you prefer.

### Setup

If you did Part 1 you should have everything you need and the files for this section are in the `alpha-blog` directory.

If you did not do Part 1 here are the prerequisites before you get started:

* The files you'll need are accessible from `https://github.com/jimcodified/dockercon2020`:

```bash
git clone https://github.com/jimcodified/dockercon2020
```

If you want to use the Snyk scanner you'll need to download it. You can sign-up and use Snyk for free at https://snyk.io/sign-up. Then you can download and install the CLI scanner or use the Snyk UI.
* A quick start for installing using the CLI is available [here](https://support.snyk.io/hc/en-us/articles/360003087017-How-to-find-vulnerabilities-using-your-CLI).
* Full docs for Snyk are at https://snyk.io/docs

---



* /usr/local/lib/ruby/site_ruby/2.7.0/rubygems/core_ext/kernel_gem.rb:67:in `synchronize': deadlock; recursive locking (ThreadError)
  * Seems related to wrong version of ruby (2.5 in original -- need to go to 2.7)
  * Change Gemfile to use Ruby 2.7
  * Still get same error - remove Gemfile.lock