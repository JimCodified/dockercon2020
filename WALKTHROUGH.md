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
git clone https://github.com/jimcodified/dockercon2020
```

If you want to use the Snyk scanner you'll need to download it. You can sign-up and use Snyk for free at https://snyk.io/sign-up. Then you can download and install the CLI scanner or use the Snyk UI.
* A quick start for installing using the CLI is available [here](https://support.snyk.io/hc/en-us/articles/360003087017-How-to-find-vulnerabilities-using-your-CLI).
* Full docs for Snyk are at https://snyk.io/docs

---

## Part 1: Fixing a simple container image

* In the first example we'll use a very simple utility container. That means there's no custom code of our own inside it, just a simple Linux utility that we install on top of a base image.

> The files for this exercise are in the `alpine-curl` folder.
> You'll also want to grab my container image so you can see a more interesting "before" state. You can do that with this command:
```bash
docker pull jimcodified/dockercon2020:curl.alp.37.orig
```

### Step-by-step

1. So from the _Four steps..._ above we don't have to worry about Step 1 because there's no code of our own in here.

2. Take a look at the Dockerfile to get some idea of what we have in our original container (`jimcodified/dockercon2020:curl.alp.37.orig` in case you haven't pulled it down yet). You can open the Dockerfile and you should see this:

```dockerfile
FROM alpine:3.7

RUN apk add --no-cache curl

ENTRYPOINT ["/usr/bin/curl"]
```
It's a very simple utility container that runs `curl`. It's built on Alpine 3.7, then adds the `curl` tool, and then runs `curl` when the container is launched.

3. Now you take a look at the container image (`docker image ls | grep jimcodified/dockercon2020`). You should see output that looks something like the below. Note that at the time of this demo, the image is nearly 2 years old. That's likely to be a problem when it comes to vulnerabilities.

```bash
jimcodified/dockercon2020           curl.alp.37.orig                                 9d899e1f01f4        23 months ago       5.5MB
```

4. Now let's do a test with the Snyk CLI to see what we find (refer to the notes above in _Setup for the exercises..._ if you haven't installed the Snyk CLI yet). 

```bash
snyk test --docker jimcodified/dockercon2020:curl.alp.37.orig --file=Dockerfile
```

You should see something like this:

![vulnerabilities](/images/demo1-original-vulns.png)

Here's a quick summary of what Snyk found, as highlighted in the image above:

> 1. Overall there are 21 vulnerabilities in this container
> 2. We're using Alpine 3.7 as our base image and it's no longer supported by the Alpine organization.
> 3. Not only is Alpine not supported, but the Alpine image we have in our container as the parent image is not even the most current Alpine 3.7 image.
> 4. And, finally, we have info about each of the vulnerabilities, and because we included our Dockerfile (`--file=Dockerfile` in the CLI) those vulnerabilities are all related back to the line in the Dockerfile where they were introduced.

5. So from the _Four steps..._ above, we already said we're skipping #1 because there is no custom code in this image. Step 2 is to address the base image. In this case we have two pointers in the results:
    * Our base image is out-of-date so we could just pull a newer `alpine:3.7` image and hope it fixes some of the vulns...or...
    * Since Alpine 3.7 is no longer supported we could go to a newer version of Alpine that is supported.
    * If you had done a `snyk monitor` instead of `snyk test` here we'd get some additional base image recommendation advice. You can try it (same exact command, just swap the word `test` for `monitor`) and when you do that your results get sent back to the Snyk service. That will give you daily updates as new vulnerabilities are discovered so you can track the image over time, but with this image you also get guidance on a better base image to use. It looks like this:
    ![snyk console](/images/demo1-base-recs.png)
    Note the "recommendation for base image upgrade" section. If we use the most current version of the Alpine 3.7 image we'll cut the vulns from the base layer down to just 1...but if we go to Alpine 3.10.2 we'll get it to 0 and - BONUS - we'll be on a supported version of Alpine. Let's do that!

6. Open the Dockerfile in your code or text editing tool of choice and change it so that it looks like this:

```dockerfile
FROM alpine:3.10.2

RUN apk add --no-cache curl

RUN addgroup --system curler && adduser --system curler curler
USER curler:curler

ENTRYPOINT ["/usr/bin/curl"]
```

What we did here is update the base image to Alpine 3.10.2 (the `FROM` line), per the guidance from Snyk's recommendations. We also made our image configuration a little better by adding the 2nd `RUN` and the `USER` commands so our utility no longer runs as root. Not strictly a vulnerability issue, but just good practice.

7. Save the new Dockerfile and then build a new image. You can tag the image however you want here - try using your own Docker Hub username and repo and tag that make sense to you so that you can push the image to save for later.

```bash
docker build -t jimcodified/dockercon2020:curl.alp.310-noroot .
```

8. Once the build completes you can verify the new image actually works (use your own container tag from the previous step)

```bash
docker run jimcodified/dockercon2020:curl.alp.310-noroot google.com
```

You should get some HTML back (it's a 301 response but we don't really care...it's working)

9. And now the important part, let's check it for vulnerabilities (again, use your custom image tag from step 7):

```bash
snyk test --docker jimcodified/dockercon2020:curl.alp.310-noroot --file=Dockerfile
```

and if all goes well you should now have zero vulnerabilities in your image. Huzzah!!

Using a newer base image removed all the vulns introduced at that layer, and by virtue of rebuilding the container we also installed the latest version of `curl` which took out all those issues, too.

This was a simple example. The next example is a little more complex and also probably much closer to what you might deal with on a daily basis. 

---

## Part 2: Fixing a more complex image

Click [here](WALKTHROUGH2.md) to go to the next example.

