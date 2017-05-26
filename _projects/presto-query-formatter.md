---
title: Presto query formatter
author: kokosing
---

Utility tool that is capable of:

 - check if provided text is a valid (parsable) Presto SQL

 - format given query

This tool is especially useful when you have a bunch of SQL files, each
formatted differently (or not formatted at all).  Thanks to this utility you
can easily check if all them are valid and format them to the same well
readable format.

<!--more-->

To check how query looks like after formating you may want to see [TPC-DS test queries](https://github.com/prestodb/presto/tree/master/presto-product-tests/src/main/resources/sql-tests/testcases/tpcds) in Presto.

If you are interested why I created yet another SQL query formatter, you want to visit this [blog post](/projects-and-sql-formatter/) where I explain the motivation behind this project.

## Installation

Currently there is no installer and there are two ways of how to use it. 
You can either build formatter by your own or download already built binary file.

### Build it on your own

That way you will be able to get the recent version. 
To build (compile and package) on your own, you need to:

~~~bash
git git@github.com:prestodb-rocks/presto-query-formatter.git
cd presto-query-formatter
mvn clean build
~~~

Above commands requires that you have [git](https://git-scm.com/) and
[maven](https://maven.apache.org/) installed.

Once it is built, you can move it to `/usr/local/bin` to make it easier to use:

~~~bash
sudo mv /target/presto-root-*-executable.jar /usr/local/bin/sqlformatter
~~~

### Download binary file

Alternatively to building you can download the compiled file from [Maven Central Repository](https://repo1.maven.org/maven2/rocks/prestodb/presto-query-formatter/0.2/)

~~~bash
wget presto-query-formatter-0.2-executable https://repo1.maven.org/maven2/rocks/prestodb/presto-query-formatter/0.2/presto-query-formatter-0.2-executable.jar
mv presto-query-formatter-0.2-executable.jar /usr/local/bin/sqlformatter
~~~

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
