# About this repo 

Docker base image for [RVM (Ruby Version Manager)](https://rvm.io).

## Why use this?

What use cases motivate dockerizing RVM, rather than using
one of the [official Ruby](https://hub.docker.com/_/ruby/) Docker images?

1. Use an [official Ruby installation method](https://www.ruby-lang.org/en/downloads/) in Docker
2. Use [RVM best practices](https://rvm.io/rvm/best-practices), such as project gemsets, in Docker
3. Easily switch between multiple Ruby versions in Docker

## Example usage

Consider a real-world example: you've discovered that a piece of code causes a
crash in one version of Ruby, but not in another.


