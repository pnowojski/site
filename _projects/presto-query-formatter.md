---
title: Presto query formatter
---

Utility tool that is capable of:

 - check if provided text is a valid (parsable) Presto SQL

 - format given query

This tool is especially useful when you have a bunch of SQL files, each
formatted differently (or not formatted at all).  Thanks to this utility you
can easily check if all them are valid and format them to the same well
readable format.

<!--more-->

## Installation

Currently there is no installer. In order to use it you need to build (compile
and package) on your own:  

~~~
git git@github.com:prestodb-rocks/presto-query-formatter.git
cd presto-query-formatter
mvn clean build
~~~

Above commands requires that you have [git](https://git-scm.com/) and
[maven](https://maven.apache.org/) installed.

Once it is built, you can add an alias to make it easier to use:

~~~
alias sqlformatter=`pwd`/target/presto-root-*-executable.jar 
~~~

Notice that to make this alias be permanent, you need to place it to a file
which will add to your session on its start. Depending on your operating system
it may differ, in case of linux and bash it might be `~/.bashrc` file.

## Usage

Presto query formatter reads SQL queries (delimited with semicolon) from
standard input and returns formatted query to standard output.

Take a look at below commands to see example usages

~~~bash
echo 'SELECT 1;' | sqlformatter

cat single.sql | sqlformatter > single.formatted.sql

cat *.sql | sqlformatter > all_sql_files_formatted_to_a_single_file.sql
~~~

## Source code
Project source code is hosted on [github](https://github.com/prestodb-rocks/presto-query-formatter).
