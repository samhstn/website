# [samhstn.com](http://samhstn.com)

### What

My monstrosity of a personal website (and reusable infrastructure for personal projects).

### Why

Various reasons ranging from learning about my own indecisiveness, to understanding how to configure aws services.

### Quick start

```bash
git clone git@github.com:samhstn/samhstn.git && cd samhstn
npm install
npm start
# the development server should now be running on: http://localhost:3000
```

### AWS

+ [The different accounts we will be working](./infra/docs/ACCOUNTS.md).
+ [Infrastructure decisions](./infra/docs/DECISIONS.md).
+ [root setup](./infra/samhstn/README.md) - aws configuration to be used by multiple projects.
+ [samhstn.com setup](./infra/samhstn.com/README.md).
+ [AWS CLI setup](./infra/docs/CLI.md).
+ [Teardown of all infrastructure setup](./infra/docs/TEARDOWN.md).
