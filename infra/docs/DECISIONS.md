# AWS Decisions

### Why have a different account for each app?

We are following approach #3 from [this article](https://winterwindsoftware.com/managing-separate-projects-in-aws/).

There are no real cons as far as I can see. I wasn't a fan of the noise of neighbouring projects in the other approaches.

### Why a bespoke solution and not use [GitHub Pages](https://pages.github.com/) or [Heroku](https://www.heroku.com/about)?

I may want to do more than what GitHub pages, Heroku or other PaaS solutions have to offer.

We don't necessarily _need_ the fine grain control/power, but if we never see the configuration options, we don't know what we are missing out on and an AWS solution will provide visibility for the configuration which PaaS solutions hide from us.

I may want to implement a more general CI/CD enterprise solution (something like [this](https://aws.amazon.com/quickstart/architecture/serverless-cicd-for-enterprise/)).

With an AWS IaaS solution, we can configure exact permissions, precisely control our automated tasks and other things.
