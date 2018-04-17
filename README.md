# About this repo

Docker base image for [RVM (Ruby Version Manager)](https://rvm.io).

## How?

Let's look at some examples:

1. Automatic install of [multiple Ruby versions](https://github.com/ms-ati/docker-rvm/blob/master/examples/Dockerfile.multi) via simple `ARG` line

### Example: Upgrading Ruby version in your app

Let's see how the [Ruby 2.4 Integer Unification](https://blog.bigbinary.com/2016/11/18/ruby-2-4-unifies-fixnum-and-bignum-into-integer.html)
impacts us.

We create a directory containing a simple `Dockerfile`:

```dockerfile
ARG RVM_RUBY_VERSIONS="2.3 2.4"
FROM msati/docker-rvm
USER ${RVM_USER}
ENV RUBY=2.3
CMD rvm ${RUBY} do irb
```

Great! Let's build it.

```bash
docker build -t rvm-irb .
```

Ok, it's built. Let's run `irb`, defaulting from our `ENV` above to Ruby 2.3:

```bash
docker run -it rvm-irb

2.3.4 :001 > 1.class
 => Fixnum
```

Great, now how easy is it to do the same in Ruby 2.4?

```bash
docker run -it -e RUBY=2.4 rvm-irb

2.4.1 :001 > 1.class
Integer
```

Very easy -- and no image rebuild necessary!

Please note that you'll probably want to use `bash -l` (that is, a
*login shell*) for any interactive consoles, since that's the easiest
way to use the RVM cli:

```bash
docker run -it rvm-irb bash -l

rvm@629159cda7a8:/$ rvm list

rvm rubies

=* ruby-2.3.4 [ x86_64 ]
   ruby-2.4.1 [ x86_64 ]

# => - current
# =* - current && default
#  * - default
```

And that's about it.

## Why?

What use cases motivate dockerizing RVM, rather than using
one of the [official Ruby](https://hub.docker.com/_/ruby/) Docker images?

1. To use an [official Ruby installation method](https://www.ruby-lang.org/en/downloads/) in Docker
2. To employ [RVM best practices](https://rvm.io/rvm/best-practices), such as project gemsets, in Docker
3. To easily switch between multiple Ruby versions in Docker, without rebuilding
   entire image on each switch

### Example: Reporting bugs in Ruby

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

# Now carry on as before -- building your project -- the base image will contain
# a layer in which all of those versions were installed by RVM.

# Later in your Dockerfile, or just interactively in a shell, switch versions
RUN rvm use --default ruby-head
```

Note that this also lowers the barrier for others in the community to jump in
and work from your reproducible test case across Ruby versions.
