# samhstn.com

[samhstn.com](http://samhstn.com)

### Requirements

```bash
$ node --version
v23.3.0

$ aws --version
aws-cli/2.22.4 Python/3.12.7 Darwin/23.6.0 source/arm64
```

ensure you have the following `.env` file set up

### Local Setup

```bash
# clone repository
git clone git@github.com:samhstn/website.git && cd website

# install dependencies
yarn install

# build the site
yarn build-css

# start the server
yarn start
```

### Writing content

1. Add a `md` file to the `blog` directory
2. To add images, add them to the assets directory
3. To add a dynamic page, just add a `md` file to the `projects` directory

After writing, run `yarn write` to upload to s3

(To read from s3, run `yarn read`)
