# About this repo 

Docker base image for [RVM (Ruby Version Manager)](https://rvm.io).

## How?

Let's look at some examples:

1. Automatic install of [multiple Ruby versions](https://github.com/ms-ati/docker-rvm/blob/master/examples/Dockerfile.multi) via simple `ARG` line

## Why?

What use cases motivate dockerizing RVM, rather than using
one of the [official Ruby](https://hub.docker.com/_/ruby/) Docker images?

1. Use an [official Ruby installation method](https://www.ruby-lang.org/en/downloads/) in Docker
2. Use [RVM best practices](https://rvm.io/rvm/best-practices), such as project gemsets, in Docker
3. Easily switch between multiple Ruby versions in Docker

## Example: reporting bugs in Ruby

Imagine that your team discovered that a piece of your code causes a crash in
one version of Ruby (let's say 2.5.1), but not in another (2.3.7).

You've [reported the issue to Ruby](https://bugs.ruby-lang.org/projects/ruby-trunk/issues),
and they've asked you to also check if the crash occurs in the trunk (aka head)
version of Ruby.

#### What do you do?

Based off of this image, it's as easy as editing an `ARG` line
at the top of your `Dockerfile`:

```dockerfile
ARG RVM_RUBY_VERSIONS="2.3.7 2.5.1 ruby-head"
FROM msati/docker-rvm

# Now carry on as before -- your base image will contain a layer in which all of
# those versions were installed by RVM.

# Later in your Dockerfile, or just interactively in a shell, switch versions
RUN rvm use --default ruby-head
```

Note that this also lowers the barrier for others in the community to jump in
and work from your reproducible test case across Ruby versions.
